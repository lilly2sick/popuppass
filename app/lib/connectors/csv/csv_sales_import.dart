import 'package:clock/clock.dart';
import '../../data/repos/product_repo.dart';
import '../../data/repos/sales_repo.dart';
import '../../domain/enums.dart';
import 'csv_import_connector.dart';

/// Imports one sale per row. Header row required:
///   id,sold_at,item,qty,unit_price,payment
/// `sold_at` is ISO 8601, prices in dollars, `payment` is a [PaymentMethod]
/// name or label. `id` is the row's externalId, so re-importing the same file
/// adds nothing; without it the id is derived from the row's contents.
/// Items matching a product by name also move its stock.
class CsvSalesImport extends CsvImportConnector<ImportedSale> {
  CsvSalesImport(super.cursors, this.sales, this.products, {super.codec});

  final SalesRepo sales;
  final ProductRepo products;

  static const header = ['id', 'sold_at', 'item', 'qty', 'unit_price', 'payment'];

  /// Products by lower-cased name, loaded per run for matching in [normalize].
  Map<String, String> _productIds = const {};

  @override
  String get id => 'csv-sales';

  @override
  Future<List<Map<String, String>>> fetch(String? cursor) async {
    final rows = await super.fetch(cursor);
    if (rows.isNotEmpty) {
      final all = await products.all();
      _productIds = {for (final p in all) p.name.toLowerCase(): p.id};
    }
    return rows;
  }

  @override
  ImportedSale normalize(Map<String, String> raw) {
    final qty = int.tryParse(raw['qty'] ?? '') ?? 1;
    final unit = codec.cents(raw['unit_price']);
    final item = raw['item'] ?? '';
    final soldAt = DateTime.tryParse(raw['sold_at'] ?? '') ?? clock.now();
    final payment = (raw['payment'] ?? '').toLowerCase();
    return ImportedSale(
      source: RecordSource.csv,
      externalId: raw['id']?.isNotEmpty == true
          ? raw['id']!
          : '${soldAt.toUtc().toIso8601String()}|$item|$qty|$unit',
      soldAt: soldAt,
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == payment || m.label.toLowerCase() == payment,
        orElse: () => PaymentMethod.other,
      ),
      totalCents: qty * unit,
      lines: [
        ImportedLine(
          name: item,
          qty: qty,
          unitPriceCents: unit,
          productId: _productIds[item.toLowerCase()],
        ),
      ],
    );
  }

  @override
  Future<int> sink(List<ImportedSale> models) => sales.importSales(models);
}
