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
        ('Cat sticker, holo', 700, 90, 3, 40),
        ('Frog pin', 1200, 340, 6, 25),
        ('Mochi keychain', 1000, 680, 22, 24),
        ('Art print A5', 1500, 210, 4, 20),
        ('Sticker pack of 5', 2000, 450, 10, 15),
      ];
      for (final (name, price, cost, mins, qty) in items) {
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
}
