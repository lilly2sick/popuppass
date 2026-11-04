import '../../data/repos/sales_repo.dart';
import '../../domain/enums.dart';
import 'payment_provider.dart';

/// Pretends to be a card reader. Each ingest yields one new card sale.
class FakePaymentProvider extends PaymentProvider {
  FakePaymentProvider(super.cursors, super.sales);

  bool _connected = false;
  int _n = 0;

  @override
  String get id => 'fake-reader';

  @override
  String get displayName => 'Demo card reader';

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  Future<List<ExternalPayment>> fetch(String? cursor) async {
    if (!_connected) return const [];
    _n++;
    return [
      ExternalPayment(
        id: 'fake-$_n',
        createdAt: DateTime.now(),
        json: {'amount': 700, 'name': 'Cat sticker'},
      ),
    ];
  }

  @override
  ImportedSale normalize(ExternalPayment raw) => ImportedSale(
    source: RecordSource.square,
    externalId: raw.id,
    soldAt: raw.createdAt,
    method: PaymentMethod.card,
    totalCents: raw.json['amount'] as int,
    lines: [
      ImportedLine(
        name: raw.json['name'] as String,
        qty: 1,
        unitPriceCents: raw.json['amount'] as int,
      ),
    ],
  );
}
