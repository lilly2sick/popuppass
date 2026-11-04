import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../domain/enums.dart';
import 'con_source.dart';

/// Stub for the AnimeCons data. The app never scrapes animecons.com: it reads
/// the public `cons` table our own backend refreshes once a day from whatever
/// feed AnimeCons agrees to provide. No auth, no user data sent.
///
/// Only used when a backend is configured and fakes are off.
class AnimeConsFeed implements ConSource {
  AnimeConsFeed({required this.supabaseUrl, required this.anonKey, Dio? http})
    : http = http ?? Dio();

  final String supabaseUrl;
  final String anonKey;
  final Dio http;

  @override
  String get id => 'animecons';

  @override
  String get attribution => 'Via animecons.com';

  @override
  Future<List<EventsCompanion>> upcoming() async {
    final res = await http.get<List<dynamic>>(
      '$supabaseUrl/rest/v1/cons',
      queryParameters: {
        'select': '*',
        'ends_at': 'gte.${DateTime.now().toUtc().toIso8601String()}',
      },
      options: Options(headers: {'apikey': anonKey}),
    );
    return [for (final c in res.data ?? const []) _toEvent(c as Map<String, dynamic>)];
  }

  EventsCompanion _toEvent(Map<String, dynamic> c) => EventsCompanion.insert(
    name: c['name'] as String,
    startsAt: DateTime.parse(c['starts_at'] as String),
    endsAt: DateTime.parse(c['ends_at'] as String),
    venue: Value(c['venue'] as String?),
    city: Value(c['city'] as String?),
    lat: Value((c['lat'] as num?)?.toDouble()),
    lng: Value((c['lng'] as num?)?.toDouble()),
    source: const Value(RecordSource.animecons),
    externalId: Value(c['external_id'] as String),
  );
}
