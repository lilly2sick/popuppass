import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/domain/enums.dart';

import 'support/repos.dart';

void main() {
  late TestRepos r;
  setUp(() => r = TestRepos());
  tearDown(() => r.close());

  test('totals and per-product rows', () async {
    final cat = await r.products.save(
      ProductsCompanion.insert(name: 'Cat', priceCents: 700, unitCostCents: const Value(100)),
    );
    final frog = await r.products.save(
      ProductsCompanion.insert(name: 'Frog', priceCents: 500, unitCostCents: const Value(200)),
    );
    await r.inventory.restock(cat, 20);
    await r.inventory.restock(frog, 20);
    final catRow = (await r.products.byId(cat))!;
    final frogRow = (await r.products.byId(frog))!;
    for (var i = 0; i < 3; i++) {
      await r.sales.recordQuickSale(product: catRow, method: PaymentMethod.cash);
    }
    await r.sales.recordQuickSale(product: frogRow, method: PaymentMethod.card);

    final report = await r.analytics.report(names: {cat: 'Cat', frog: 'Frog'});
    expect(report.grossCents, 3 * 700 + 500);
    expect(report.costCents, 3 * 100 + 200);
    expect(report.units, 4);
    expect(report.netCents, 2600 - 500);
    expect(report.byMethod[PaymentMethod.cash], 2100);
    expect(report.byMethod[PaymentMethod.card], 500);

    final ranked = report.ranked;
    expect(ranked.first.name, 'Cat');
    expect(ranked.first.units, 3);
    expect(ranked.first.profitCents, 1800);
    expect(ranked.last.name, 'Frog');
    expect(ranked.last.margin, closeTo(0.6, 1e-9));
  });

  test('booth fee comes off net', () async {
    final eventId = await r.events.save(
      EventsCompanion.insert(
        name: 'Con',
        startsAt: DateTime(2026, 1, 1),
        endsAt: DateTime(2026, 1, 2),
        boothFeeCents: const Value(12000),
      ),
    );
    final event = (await r.events.byId(eventId))!;
    final report = await r.analytics.report(event: event);
    expect(report.netCents, -12000);
  });
}
