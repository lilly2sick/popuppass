import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repos/sales_repo.dart';
import '../../domain/enums.dart';
import 'payment_provider.dart';

/// Square card sales -> local sales ledger.
///
/// OAuth: the app opens Square's authorize page; the `square-token` Edge
/// Function exchanges the code (it holds the client secret) and returns
/// tokens, which live only in secure storage on this phone.
///
/// Each completed payment is fetched with its order, so imported sales carry
/// the real line items. A 401 refreshes the token once and retries.
class SquareProvider extends PaymentProvider {
  SquareProvider(
    super.cursors,
    super.sales, {
    required this.appId,
    required this.storage,
    required this.tokenExchange,
    required this.authorize,
    Dio? http,
  }) : http = http ?? Dio(BaseOptions(baseUrl: 'https://connect.squareup.com'));

  /// Square application id (config.dart `squareAppId`).
  final String appId;
  final FlutterSecureStorage storage;

  /// Calls the `square-token` Edge Function. Injected so tests can fake it.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body) tokenExchange;

  /// Opens [url] in a system browser session and returns the redirect URL the
  /// session ended on. Injected so tests and fakes need no platform plugin.
  final Future<String> Function(Uri url, String callbackScheme) authorize;
  final Dio http;

  static const callbackScheme = 'popuppass';
  static const _redirect = '$callbackScheme://square';
  static const _version = '2024-10-17';
  static const _accessKey = 'square.access_token';
  static const _refreshKey = 'square.refresh_token';

  @override
  String get id => 'square';

  @override
  String get displayName => 'Square';

  @override
  Future<bool> get isConnected async => (await storage.read(key: _accessKey)) != null;

  @override
  Future<void> connect() async {
    if (appId.isEmpty) throw StateError('SQUARE_APP_ID is not configured');
    final state = _randomState();
    final result = Uri.parse(
      await authorize(
        Uri.https('connect.squareup.com', '/oauth2/authorize', {
          'client_id': appId,
          'scope': 'PAYMENTS_READ ORDERS_READ ITEMS_READ',
          'session': 'false',
          'state': state,
        }),
        callbackScheme,
      ),
    );
    final code = result.queryParameters['code'];
    if (result.queryParameters['state'] != state || code == null) {
      throw StateError('Square authorization was cancelled or failed');
    }
    await _saveTokens(
      await tokenExchange({
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirect,
      }),
    );
  }

  String _randomState() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
  }

  Future<void> _saveTokens(Map<String, dynamic> t) async {
    await storage.write(key: _accessKey, value: t['access_token'] as String);
    final refresh = t['refresh_token'] as String?;
    if (refresh != null) await storage.write(key: _refreshKey, value: refresh);
  }

  /// Exchanges the refresh token. False when there is none or Square refuses.
  Future<bool> _refresh() async {
    final refresh = await storage.read(key: _refreshKey);
    if (refresh == null) return false;
    try {
      await _saveTokens(
        await tokenExchange({'grant_type': 'refresh_token', 'refresh_token': refresh}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// GET with the stored token; one refresh-and-retry on 401.
  Future<Map<String, dynamic>> _get(String path, [Map<String, dynamic>? query]) async {
    Future<Response<Map<String, dynamic>>> call() async => http.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await storage.read(key: _accessKey)}',
          'Square-Version': _version,
        },
      ),
    );
    try {
      return (await call()).data ?? const {};
    } on DioException catch (e) {
      if (e.response?.statusCode != 401 || !await _refresh()) rethrow;
      return (await call()).data ?? const {};
    }
  }

  @override
  Future<void> disconnect() async {
    await storage.delete(key: _accessKey);
    await storage.delete(key: _refreshKey);
  }

  @override
  Future<List<ExternalPayment>> fetch(String? cursor) async {
    if (await storage.read(key: _accessKey) == null) return const [];
    final out = <ExternalPayment>[];
    String? page;
    do {
      final body = await _get('/v2/payments', {
        if (cursor != null) 'begin_time': cursor,
        'sort_order': 'ASC',
        if (page != null) 'cursor': page,
      });
      for (final p in (body['payments'] as List? ?? const [])) {
        final m = p as Map<String, dynamic>;
        if (m['status'] != 'COMPLETED') continue;
        final orderId = m['order_id'] as String?;
        final order = orderId == null ? null : (await _get('/v2/orders/$orderId'))['order'];
        out.add(
          ExternalPayment(
            id: m['id'] as String,
            createdAt: DateTime.parse(m['created_at'] as String),
            json: {...m, if (order != null) 'order': order},
          ),
        );
      }
      page = body['cursor'] as String?;
    } while (page != null);
    return out;
  }

  @override
  ImportedSale normalize(ExternalPayment raw) {
    final j = raw.json;
    final amount = (j['amount_money'] as Map?)?['amount'] as int? ?? 0;
    final items = (j['order'] as Map?)?['line_items'] as List? ?? const [];
    final lines = [
      for (final i in items.cast<Map<String, dynamic>>())
        ImportedLine(
          name: i['name'] as String? ?? 'Square item',
          qty: int.tryParse('${i['quantity']}') ?? 1,
          unitPriceCents: (i['base_price_money'] as Map?)?['amount'] as int? ?? 0,
          externalItemId: i['catalog_object_id'] as String?,
        ),
    ];
    return ImportedSale(
      source: RecordSource.square,
      externalId: raw.id,
      soldAt: raw.createdAt,
      method: _method(j),
      totalCents: amount,
      lines: lines.isEmpty
          ? [ImportedLine(name: 'Square sale', qty: 1, unitPriceCents: amount)]
          : lines,
    );
  }

  PaymentMethod _method(Map<String, dynamic> j) => switch (j['source_type']) {
    'CARD' || 'WALLET' => PaymentMethod.card,
    'CASH' => PaymentMethod.cash,
    _ => PaymentMethod.other,
  };
}
