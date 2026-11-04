import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../data/repos/product_repo.dart';
import '../connector.dart';

/// Imports products from CSV. Header row required:
///   name,price,cost,quantity,minutes,tags
/// Prices in dollars. Tags separated by `|`. Also accepts our own export.
class CsvProductImport extends Connector<Map<String, String>, (ProductsCompanion, int)> {
  CsvProductImport(super.cursors, this.products, this.restock);

  final ProductRepo products;
  final Future<void> Function(String productId, int qty) restock;
  String? pendingText;

  @override
  String get id => 'csv-products';

  @override
  Future<List<Map<String, String>>> fetch(String? cursor) async {
    final text = pendingText;
    pendingText = null;
    if (text == null) return const [];
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(text.replaceAll('\r\n', '\n'));
    if (rows.isEmpty) return const [];
    final header = [for (final h in rows.first) h.toString().trim().toLowerCase()];
    return [
      for (final r in rows.skip(1))
        if (r.isNotEmpty && r.first.toString().trim().isNotEmpty)
          {for (var i = 0; i < header.length && i < r.length; i++) header[i]: r[i].toString().trim()},
    ];
  }

  int _cents(String? v) => ((double.tryParse((v ?? '').replaceAll(r'$', '')) ?? 0) * 100).round();

  @override
  (ProductsCompanion, int) normalize(Map<String, String> r) => (
        ProductsCompanion.insert(
          name: r['name']!,
          priceCents: _cents(r['price']),
          unitCostCents: Value(_cents(r['cost'])),
          minutesToMake: Value(int.tryParse(r['minutes'] ?? '')),
          tags: Value((r['tags'] ?? '').split('|').where((t) => t.isNotEmpty).toList()),
        ),
        int.tryParse(r['quantity'] ?? '') ?? 0,
      );

  @override
  Future<int> sink(List<(ProductsCompanion, int)> models) async {
    for (final (p, qty) in models) {
      final id = await products.save(p);
      if (qty > 0) await restock(id, qty);
    }
    return models.length;
  }
}
