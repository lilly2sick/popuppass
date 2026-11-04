import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/data/repos/sales_repo.dart';
import 'package:popup_pass/domain/enums.dart';

import 'support/repos.dart';

void main() {
  late TestRepos r;
  setUp(() => r = TestRepos());
  tearDown(() => r.close());

  test('sales dedupe on (source, externalId)', () async {
    final incoming = ImportedSale(
      source: RecordSource.square,
      externalId: 'sq-1',
      soldAt: DateTime.now(),
      method: PaymentMethod.card,
      totalCents: 700,
      lines: const [ImportedLine(name: 'Cat sticker', qty: 1, unitPriceCents: 700)],
    );
    expect(await r.sales.importSales([incoming]), 1);
    expect(await r.sales.importSales([incoming]), 0);
    expect(await r.sales.watchAll().first, hasLength(1));
  });

  test('events dedupe on (source, externalId)', () async {
    final event = EventsCompanion(
      name: const Value('Sample Con'),
      startsAt: Value(DateTime(2026, 6, 1)),
      endsAt: Value(DateTime(2026, 6, 3)),
      source: const Value(RecordSource.animecons),
      externalId: const Value('ac-1'),
    );
    expect(await r.events.importAll([event]), 1);
    expect(await r.events.importAll([event]), 0);
    expect(await r.events.watchAll().first, hasLength(1));
  });
}
