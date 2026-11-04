import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/connectors/csv/csv_codec.dart';
import 'package:popup_pass/connectors/csv/csv_product_import.dart';
import 'package:popup_pass/connectors/csv/csv_sales_import.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/domain/enums.dart';

import 'support/repos.dart';

void main() {
  late TestRepos r;
  late TestRepos other;
  setUp(() {
    r = TestRepos();
    other = TestRepos();
  });
  tearDown(() async {
    await r.close();
    await other.close();
  });

  CsvProductImport importer(TestRepos t) =>
      CsvProductImport(t.cursors, t.products, (id, qty) => t.inventory.restock(id, qty));

  test('products survive export then import, including commas and tags', () async {
    final id = await r.products.save(
      ProductsCompanion.insert(
        name: 'Sticker pack, 5 pcs',
        priceCents: 1550,
        unitCostCents: const Value(320),
        minutesToMake: const Value(12),
        tags: const Value(['holo', 'cat']),
      ),
    );
    await r.inventory.restock(id, 14);

    final product = (await r.products.byId(id))!;
    final csv = const CsvCodec().write([
      CsvProductImport.header,
      CsvProductImport.rowFor(product, 14),
    ]);

    final target = importer(other)..pendingText = csv;
    final result = await target.ingest();
    expect(result.ok, isTrue);
    expect(result.added, 1);

    final imported = (await other.products.all()).single;
    expect(imported.name, 'Sticker pack, 5 pcs');
    expect(imported.priceCents, 1550);
    expect(imported.unitCostCents, 320);
    expect(imported.minutesToMake, 12);
    expect(imported.tags, ['holo', 'cat']);
    expect((await other.inventory.watchStock().first)[imported.id], 14);
  });

  test('importing the same products file twice adds nothing', () async {
    const csv = 'name,price,cost,quantity\nFrog pin,\$8.00,\$2.00,5\n';
    expect((await (importer(r)..pendingText = csv).ingest()).added, 1);
    final again = await (importer(r)..pendingText = csv).ingest();
    expect(again.added, 0);
    expect(await r.products.all(), hasLength(1));
    expect((await r.inventory.watchStock().first).values.single, 5);
  });

  test('sales import matches products, moves stock and dedupes by id', () async {
    final id = await r.products.save(ProductsCompanion.insert(name: 'Frog pin', priceCents: 800));
    await r.inventory.restock(id, 10);
    const csv =
        'id,sold_at,item,qty,unit_price,payment\n'
        's1,2026-11-06T18:00:00Z,Frog pin,2,8.00,cash\n'
        's2,2026-11-06T19:00:00Z,Mystery thing,1,5.00,Venmo\n';
    CsvSalesImport sales() => CsvSalesImport(r.cursors, r.sales, r.products);

    final first = await (sales()..pendingText = csv).ingest();
    expect(first.added, 2);
    expect((await r.inventory.watchStock().first)[id], 8);

    final second = await (sales()..pendingText = csv).ingest();
    expect(second.added, 0);
    expect((await r.inventory.watchStock().first)[id], 8);

    final report = await r.analytics.report();
    expect(report.grossCents, 2100);
    expect(report.byMethod[PaymentMethod.venmo], 500);
  });
}
