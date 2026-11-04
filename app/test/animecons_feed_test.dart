import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/connectors/events/animecons_feed.dart';
import 'package:popup_pass/connectors/events/fake_con_source.dart';
import 'package:popup_pass/domain/enums.dart';

import 'support/repos.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? seen;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    seen = options;
    return ResponseBody.fromString(
      jsonEncode([
        {
          'name': 'Sample Con',
          'starts_at': '2026-12-04T08:00:00Z',
          'ends_at': '2026-12-06T22:00:00Z',
          'venue': 'Hall A',
          'city': 'Oakland',
          'lat': 37.8,
          'lng': -122.27,
          'external_id': 'ac-42',
        },
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('reads our own cons table with the anon key and maps rows', () async {
    final adapter = _Adapter();
    final feed = AnimeConsFeed(
      supabaseUrl: 'https://project.test',
      anonKey: 'anon',
      http: Dio()..httpClientAdapter = adapter,
    );
    final cons = await feed.upcoming();
    expect(adapter.seen!.uri.host, 'project.test');
    expect(adapter.seen!.uri.path, '/rest/v1/cons');
    expect(adapter.seen!.headers['apikey'], 'anon');
    expect(cons.single.name.value, 'Sample Con');
    expect(cons.single.source.value, RecordSource.animecons);
    expect(cons.single.externalId.value, 'ac-42');
    expect(feed.attribution, contains('animecons.com'));
  });

  test('adding the same con twice stores it once', () async {
    final r = TestRepos();
    addTearDown(r.close);
    final cons = await FakeConSource().upcoming();
    expect(cons, hasLength(3));
    expect(await r.events.importAll(cons), 3);
    expect(await r.events.importAll(cons), 0);
  });
}
