import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/connectors/payment/square_provider.dart';
import 'package:popup_pass/domain/enums.dart';

import 'support/repos.dart';

/// Answers Square's REST calls from a script; no network.
class _MockSquare implements HttpClientAdapter {
  _MockSquare(this.handler);

  final ResponseBody Function(RequestOptions) handler;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    calls.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  late TestRepos r;
  late FlutterSecureStorage storage;
  late List<Map<String, dynamic>> exchanges;

  setUp(() {
    r = TestRepos();
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    exchanges = [];
  });
  tearDown(() => r.close());

  SquareProvider provider(_MockSquare adapter, {String Function(Uri)? redirect}) => SquareProvider(
    r.cursors,
    r.sales,
    appId: 'sq-app',
    storage: storage,
    tokenExchange: (body) async {
      exchanges.add(body);
      return {'access_token': 'fresh-token', 'refresh_token': 'fresh-refresh'};
    },
    authorize: (url, scheme) async {
      final state = url.queryParameters['state'];
      return '$scheme://square?code=abc&state=$state';
    },
    http: Dio(BaseOptions(baseUrl: 'https://square.test'))..httpClientAdapter = adapter,
  );

  Map<String, dynamic> payment(String id, {String status = 'COMPLETED', String? orderId}) => {
    'id': id,
    'status': status,
    'created_at': '2026-11-06T18:00:00Z',
    'source_type': 'CARD',
    'amount_money': {'amount': 700, 'currency': 'USD'},
    'order_id': ?orderId,
  };

  test('connect runs OAuth, exchanges the code and stores tokens', () async {
    final p = provider(_MockSquare((_) => _json({})));
    expect(await p.isConnected, isFalse);
    await p.connect();
    expect(await p.isConnected, isTrue);
    expect(exchanges.single['grant_type'], 'authorization_code');
    expect(exchanges.single['code'], 'abc');
    await p.disconnect();
    expect(await p.isConnected, isFalse);
  });

  test('connect refuses without an app id', () async {
    final p = SquareProvider(
      r.cursors,
      r.sales,
      appId: '',
      storage: storage,
      tokenExchange: (_) async => {},
      authorize: (_, __) async => '',
    );
    expect(p.connect(), throwsStateError);
  });

  test('ingest maps completed payments to sales and dedupes on re-run', () async {
    await storage.write(key: 'square.access_token', value: 'tok');
    final adapter = _MockSquare((o) {
      if (o.path.startsWith('/v2/orders/')) {
        return _json({
          'order': {
            'line_items': [
              {
                'name': 'Cat sticker',
                'quantity': '2',
                'base_price_money': {'amount': 350},
              },
            ],
          },
        });
      }
      return _json({
        'payments': [payment('pay-1', orderId: 'o1'), payment('pay-2', status: 'FAILED')],
      });
    });
    final p = provider(adapter);

    final first = await p.ingest();
    expect(first.ok, isTrue);
    expect(first.fetched, 1);
    expect(first.added, 1);

    final sale = (await r.sales.watchAll().first).single;
    expect(sale.source, RecordSource.square);
    expect(sale.externalId, 'pay-1');
    expect(sale.paymentMethod, PaymentMethod.card);
    expect(sale.totalCents, 700);
    final lines = await r.db.select(r.db.saleLines).get();
    expect(lines.single.externalName, 'Cat sticker');
    expect(lines.single.qty, 2);

    expect((await p.ingest()).added, 0);
    expect(adapter.calls.first.headers['Authorization'], 'Bearer tok');
  });

  test('the cursor moves forward and is sent as begin_time next run', () async {
    await storage.write(key: 'square.access_token', value: 'tok');
    final adapter = _MockSquare(
      (_) => _json({
        'payments': [payment('pay-1')],
      }),
    );
    final p = provider(adapter);
    await p.ingest();
    await p.ingest();
    expect(adapter.calls.first.queryParameters.containsKey('begin_time'), isFalse);
    expect(adapter.calls.last.queryParameters['begin_time'], '2026-11-06T18:00:00.000Z');
  });

  test('a 401 refreshes the token once and retries', () async {
    await storage.write(key: 'square.access_token', value: 'stale');
    await storage.write(key: 'square.refresh_token', value: 'refresh');
    final adapter = _MockSquare((o) {
      final stale = o.headers['Authorization'] == 'Bearer stale';
      return stale
          ? _json({'errors': []}, 401)
          : _json({
              'payments': [payment('pay-1')],
            });
    });
    final result = await provider(adapter).ingest();
    expect(result.ok, isTrue);
    expect(result.added, 1);
    expect(exchanges.single['grant_type'], 'refresh_token');
    expect(await storage.read(key: 'square.access_token'), 'fresh-token');
  });

  test('without a token ingest is a quiet no-op', () async {
    final adapter = _MockSquare((_) => _json({}));
    final result = await provider(adapter).ingest();
    expect(result.fetched, 0);
    expect(adapter.calls, isEmpty);
  });
}
