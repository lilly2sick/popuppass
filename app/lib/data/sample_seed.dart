import 'package:drift/drift.dart';

import '../domain/enums.dart';
import 'db/database.dart';
import 'db/tables.dart' show newId;

/// Demo shop "Mochi Paws Stickers" at a live con, so the whole app works
/// offline with no keys. Only runs when the database is empty.
class SampleSeed {
  SampleSeed(this.db);

  final AppDatabase db;

  Future<void> seedIfEmpty() async {
    if ((await db.select(db.products).get()).isNotEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await db.transaction(() async {
      await db
          .into(db.brands)
          .insert(
            BrandsCompanion.insert(
              shopName: 'Mochi Paws Stickers',
              handle: const Value('@mochipaws'),
              boothLabel: const Value('Booth A-14'),
              nicheTags: const Value(['anime', 'cute', 'cottagecore']),
            ),
          );

      final eventId = newId();
      await db
          .into(db.events)
          .insert(
            EventsCompanion.insert(
              id: Value(eventId),
              name: 'Anime Fest 2026',
              startsAt: today.subtract(const Duration(days: 1)).add(const Duration(hours: 9)),
              endsAt: today.add(const Duration(days: 1, hours: 18)),
              boothFeeCents: const Value(12000),
              boothLabel: const Value('Booth A-14'),
            ),
          );

      final items = [
        ('Cat sticker, holo', 700, 90, 3, 40, 37),
        ('Frog pin', 1200, 340, 6, 25, 8),
        ('Mochi keychain', 1000, 680, 22, 24, 3),
        ('Art print A5', 1500, 210, 4, 20, 2),
        ('Sticker pack of 5', 2000, 450, 10, 15, 9),
      ];
      var minute = 0;
      for (final (name, price, cost, mins, qty, sold) in items) {
        final id = newId();
        await db
            .into(db.products)
            .insert(
              ProductsCompanion.insert(
                id: Value(id),
                name: name,
                priceCents: price,
                unitCostCents: Value(cost),
                minutesToMake: Value(mins),
                tags: const Value(['anime']),
              ),
            );
        await db
            .into(db.inventoryMoves)
            .insert(
              InventoryMovesCompanion.insert(
                productId: id,
                delta: qty,
                reason: MoveReason.restock,
                eventId: Value(eventId),
              ),
            );
        for (var i = 0; i < sold; i++) {
          minute += 3;
          await _sell(id, eventId, price, cost, today.add(Duration(hours: 8, minutes: minute)));
        }
      }

      final trends = [
        (
          'frog-mushroom',
          'frog',
          'cottagecore',
          0.92,
          'Frog and mushroom friends',
          'Cozy nature motifs fit a cute sticker shop.',
          ['Pinterest', 'Reddit', 'Curated'],
        ),
        (
          'strawberry-milk',
          'strawberry milk',
          'cute',
          0.81,
          'Strawberry milk moments',
          'Sweet colors make an easy mini collection.',
          ['Etsy', 'Curated'],
        ),
        (
          'black-cat',
          'black cat',
          'anime',
          0.77,
          'Black cat energy',
          'A companion piece for your best seller.',
          ['AniList', 'Curated'],
        ),
      ];
      for (final (id, kw, niche, score, title, why, sources) in trends) {
        await db
            .into(db.trendCache)
            .insert(
              TrendCacheCompanion.insert(
                id: id,
                keyword: kw,
                niche: niche,
                score: score,
                title: title,
                why: why,
                sources: sources,
                snapshotVersion: 'sample',
              ),
            );
      }
    });
  }

  /// One cash sale of one unit, with its stock move.
  Future<void> _sell(String productId, String eventId, int price, int cost, DateTime at) async {
    final saleId = newId();
    final lineId = newId();
    await db
        .into(db.sales)
        .insert(
          SalesCompanion.insert(
            id: Value(saleId),
            eventId: Value(eventId),
            soldAt: Value(at),
            paymentMethod: PaymentMethod.cash,
            totalCents: price,
          ),
        );
    await db
        .into(db.saleLines)
        .insert(
          SaleLinesCompanion.insert(
            id: Value(lineId),
            saleId: saleId,
            productId: Value(productId),
            qty: 1,
            unitPriceCents: price,
            unitCostCents: cost,
          ),
        );
    await db
        .into(db.inventoryMoves)
        .insert(
          InventoryMovesCompanion.insert(
            productId: productId,
            delta: -1,
            reason: MoveReason.sale,
            eventId: Value(eventId),
            saleLineId: Value(lineId),
          ),
        );
  }
}
