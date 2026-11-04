import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/domain/enums.dart';

import 'support/repos.dart';

void main() {
  late TestRepos r;
  late Product cat;

  Future<int> stock() async => (await r.inventory.watchStock().first)[cat.id] ?? 0;

  setUp(() async {
    r = TestRepos();
    final id = await r.products.save(
      ProductsCompanion.insert(
        name: 'Cat sticker',
        priceCents: 700,
        unitCostCents: const Value(90),
      ),
    );
    await r.inventory.restock(id, 10);
    cat = (await r.products.byId(id))!;
  });
  tearDown(() => r.close());

  test('a sale takes one unit off the shelf', () async {
    await r.sales.recordQuickSale(product: cat, method: PaymentMethod.cash);
    expect(await stock(), 9);
  });

  test('undo (-1) puts the unit back and the sale stops counting', () async {
    final id = await r.sales.recordQuickSale(product: cat, method: PaymentMethod.cash);
    await r.sales.voidSale(id);
    expect(await stock(), 10);
    expect((await r.analytics.report()).units, 0);
  });

  test('sell three, undo one leaves eight on hand and two sold', () async {
    final ids = [
      for (var i = 0; i < 3; i++)
        await r.sales.recordQuickSale(product: cat, method: PaymentMethod.card),
    ];
    await r.sales.voidSale(ids.last);
    expect(await stock(), 8);
    expect((await r.analytics.report()).units, 2);
  });

  test('price edits are kept in price history', () async {
    await r.products.save(
      ProductsCompanion.insert(id: Value(cat.id), name: cat.name, priceCents: 800),
    );
    final history = await r.db.select(r.db.priceHistory).get();
    expect(history.map((h) => h.priceCents), containsAll([700, 800]));
  });
}
