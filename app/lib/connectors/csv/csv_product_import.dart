import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../data/repos/product_repo.dart';
import 'csv_import_connector.dart';

/// A product row plus the units on hand the file says to stock.
typedef ProductImport = ({ProductsCompanion product, int quantity});

/// Imports products. Header row required:
///   name,price,cost,quantity,minutes,tags
/// Prices in dollars, tags separated by `|`. Matches the file produced by
/// [header] / [rowFor], so our own export imports cleanly.
///
/// Rows are deduped on name (case-insensitive): an existing product is
/// updated and not restocked a second time.
class CsvProductImport extends CsvImportConnector<ProductImport> {
  CsvProductImport(super.cursors, this.products, this.restock, {super.codec});

  final ProductRepo products;
  final Future<void> Function(String productId, int qty) restock;

  static const header = ['name', 'price', 'cost', 'quantity', 'minutes', 'tags'];

  /// One export row for [p] with [quantity] on hand.
  static List<Object?> rowFor(Product p, int quantity) => [
    p.name,
    (p.priceCents / 100).toStringAsFixed(2),
    (p.unitCostCents / 100).toStringAsFixed(2),
    quantity,
    p.minutesToMake,
    p.tags.join('|'),
  ];

  @override
  String get id => 'csv-products';

  @override
  ProductImport normalize(Map<String, String> raw) => (
    product: ProductsCompanion.insert(
      name: raw['name']!,
      priceCents: codec.cents(raw['price']),
      unitCostCents: Value(codec.cents(raw['cost'])),
      minutesToMake: Value(int.tryParse(raw['minutes'] ?? '')),
      tags: Value((raw['tags'] ?? '').split('|').where((t) => t.isNotEmpty).toList()),
    ),
    quantity: int.tryParse(raw['quantity'] ?? '') ?? 0,
  );

  @override
  Future<int> sink(List<ProductImport> models) async {
    var added = 0;
    for (final m in models) {
      final existing = await products.findByName(m.product.name.value);
      final id = await products.save(
        existing == null ? m.product : m.product.copyWith(id: Value(existing.id)),
      );
      if (existing != null) continue;
      added++;
      if (m.quantity > 0) await restock(id, m.quantity);
    }
    return added;
  }
}
