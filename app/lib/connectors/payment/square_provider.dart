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
class SquareProvider extends PaymentProvider {
  SquareProvider(
    super.cursors,
    super.sales, {
    required this.storage,
    required this.tokenExchange,
    Dio? http,
  }) : http = http ?? Dio(BaseOptions(baseUrl: 'https://connect.squareup.com'));

  final FlutterSecureStorage storage;

  /// Calls the `square-token` Edge Function. Injected so tests can fake it.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body) tokenExchange;
  final Dio http;

  static const _accessKey = 'square.access_token';
  static const _refreshKey = 'square.refresh_token';

  /// Square catalog variation id -> local product id.
  Map<String, String> catalogMap = const {};

  @override
  String get id => 'square';

  @override
  String get displayName => 'Square';

  @override
  Future<bool> get isConnected async => (await storage.read(key: _accessKey)) != null;

  @override
  Future<void> connect() async {
    // TODO(square): open authorize URL with flutter_web_auth_2, capture `code`,
    // then: final t = await tokenExchange({'grant_type': 'authorization_code', 'code': code});
    // await _saveTokens(t);
    throw UnimplementedError('Square OAuth not wired yet');
  }

  @override
  Future<void> disconnect() async {
    await storage.delete(key: _accessKey);
    await storage.delete(key: _refreshKey);
  }

  @override
  Future<List<ExternalPayment>> fetch(String? cursor) async {
    final token = await storage.read(key: _accessKey);
    if (token == null) return const [];
    final out = <ExternalPayment>[];
    String? page;
    do {
      final res = await http.get<Map<String, dynamic>>(
        '/v2/payments',
        queryParameters: {
          if (cursor != null) 'begin_time': cursor,
          'sort_order': 'ASC',
          if (page != null) 'cursor': page,
        },
        options: Options(headers: {'Authorization': 'Bearer $token', 'Square-Version': '2024-10-17'}),
      );
      final body = res.data ?? const {};
      for (final p in (body['payments'] as List? ?? const [])) {
        final m = p as Map<String, dynamic>;
        if (m['status'] != 'COMPLETED') continue;
        out.add(ExternalPayment(id: m['id'] as String, createdAt: DateTime.parse(m['created_at'] as String), json: m));
      }
      page = body['cursor'] as String?;
    } while (page != null);
    // TODO(square): on 401, refresh via tokenExchange({'grant_type': 'refresh_token', ...}) and retry once.
    // TODO(square): fetch order line items (Orders API, by order_id) to fill ImportedLine per item.
    return out;
  }

  @override
  ImportedSale normalize(ExternalPayment raw) {
    final j = raw.json;
    final amount = (j['amount_money'] as Map?)?['amount'] as int? ?? 0;
    return ImportedSale(
      source: RecordSource.square,
      externalId: raw.id,
      soldAt: raw.createdAt,
      method: _method(j),
      totalCents: amount,
      lines: [ImportedLine(name: 'Square sale', qty: 1, unitPriceCents: amount)],
    );
  }

  PaymentMethod _method(Map<String, dynamic> j) => switch (j['source_type']) {
        'CARD' || 'WALLET' => PaymentMethod.card,
        'CASH' => PaymentMethod.cash,
        _ => PaymentMethod.other,
      };
}
