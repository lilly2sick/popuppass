import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/database.dart';
import 'inventory_repo.dart';
import 'product_repo.dart';
import 'repository.dart';

/// A sale coming from a connector (Square, CSV) before it is stored.
class ImportedSale {
  const ImportedSale({
    required this.source,
    required this.externalId,
    required this.soldAt,
    required this.method,
    required this.totalCents,
    required this.lines,
  });

  final RecordSource source;
  final String externalId;
  final DateTime soldAt;
  final PaymentMethod method;
  final int totalCents;
  final List<ImportedLine> lines;
}

class ImportedLine {
  const ImportedLine({
    required this.name,
    required this.qty,
    required this.unitPriceCents,
    this.productId,
    this.externalItemId,
  });

  final String name;
  final int qty;
  final int unitPriceCents;
  final String? productId;
  final String? externalItemId;
}

class SalesRepo extends Repository<Sale> {
  SalesRepo(super.db, super.tracker, super.deviceId, this.products, this.inventory);

  final ProductRepo products;
  final InventoryRepo inventory;

  @override
  String get entity => 'sales';

  @override
  Stream<List<Sale>> watchAll() =>
      (db.select(db.sales)
            ..where((s) => s.deleted.equals(false))
            ..orderBy([(s) => OrderingTerm.desc(s.soldAt)]))
          .watch();

  Stream<List<Sale>> watchForEvent(String eventId) =>
      (db.select(db.sales)
            ..where((s) => s.deleted.equals(false) & s.eventId.equals(eventId))
            ..orderBy([(s) => OrderingTerm.desc(s.soldAt)]))
          .watch();

  @override
  Future<Sale?> byId(String id) =>
      (db.select(db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// The +1 sold tap. Sale, line and stock move are written in one transaction.
  Future<String> recordQuickSale({
    required Product product,
    required PaymentMethod method,
    String? eventId,
    int qty = 1,
  }) async {
    final cost = await products.unitCost(product.id);
    return db.transaction(() async {
      final saleId = makeId();
      final lineId = makeId();
      await db
          .into(db.sales)
          .insert(
            SalesCompanion.insert(
              id: Value(saleId),
              eventId: Value(eventId),
              paymentMethod: method,
              totalCents: product.priceCents * qty,
              deviceId: Value(deviceId),
            ),
          );
      await db
          .into(db.saleLines)
          .insert(
            SaleLinesCompanion.insert(
              id: Value(lineId),
              saleId: saleId,
              productId: Value(product.id),
              qty: qty,
              unitPriceCents: product.priceCents,
              unitCostCents: cost,
              deviceId: Value(deviceId),
            ),
          );
      await inventory.move(
        productId: product.id,
        delta: -qty,
        reason: MoveReason.sale,
        eventId: eventId,
        saleLineId: lineId,
      );
      await touched(saleId);
      await tracker.record('sale_lines', lineId, SyncOp.upsert);
      return saleId;
    });
  }

  /// Undo: soft-delete the sale and return stock with a `voided` move.
  Future<void> voidSale(String saleId) => db.transaction(() async {
    final lines = await (db.select(db.saleLines)..where((l) => l.saleId.equals(saleId))).get();
    final sale = await byId(saleId);
    for (final l in lines) {
      if (l.productId == null) continue;
      await inventory.move(
        productId: l.productId!,
        delta: l.qty,
        reason: MoveReason.voided,
        eventId: sale?.eventId,
        saleLineId: l.id,
      );
    }
    await softDelete(saleId);
  });

  /// Dedupes on (source, externalId). Returns how many were new.
  Future<int> importSales(List<ImportedSale> incoming, {String? eventId}) async {
    var added = 0;
    await db.transaction(() async {
      for (final s in incoming) {
        final exists =
            await (db.select(
                  db.sales,
                )..where((x) => x.source.equalsValue(s.source) & x.externalId.equals(s.externalId)))
                .getSingleOrNull();
        if (exists != null) continue;
        added++;
        final saleId = makeId();
        await db
            .into(db.sales)
            .insert(
              SalesCompanion.insert(
                id: Value(saleId),
                eventId: Value(eventId),
                soldAt: Value(s.soldAt),
                paymentMethod: s.method,
                source: Value(s.source),
                externalId: Value(s.externalId),
                totalCents: s.totalCents,
                deviceId: Value(deviceId),
              ),
            );
        for (final l in s.lines) {
          final lineId = makeId();
          final cost = l.productId == null ? 0 : await products.unitCost(l.productId!);
          await db
              .into(db.saleLines)
              .insert(
                SaleLinesCompanion.insert(
                  id: Value(lineId),
                  saleId: saleId,
                  productId: Value(l.productId),
                  externalName: Value(l.name),
                  qty: l.qty,
                  unitPriceCents: l.unitPriceCents,
                  unitCostCents: cost,
                  deviceId: Value(deviceId),
                ),
              );
          if (l.productId != null) {
            await inventory.move(
              productId: l.productId!,
              delta: -l.qty,
              reason: MoveReason.sale,
              eventId: eventId,
              saleLineId: lineId,
            );
          }
          await tracker.record('sale_lines', lineId, SyncOp.upsert);
        }
        await touched(saleId);
      }
    });
    return added;
  }

  /// Lines with their sale, for analytics.
  Future<List<(Sale, SaleLine)>> linesFor({String? eventId, DateTime? from, DateTime? to}) async {
    final q = db.select(db.saleLines).join([
      innerJoin(db.sales, db.sales.id.equalsExp(db.saleLines.saleId)),
    ])..where(db.sales.deleted.equals(false) & db.saleLines.deleted.equals(false));
    if (eventId != null) q.where(db.sales.eventId.equals(eventId));
    if (from != null) q.where(db.sales.soldAt.isBiggerOrEqualValue(from));
    if (to != null) q.where(db.sales.soldAt.isSmallerThanValue(to));
    final rows = await q.get();
    return [for (final r in rows) (r.readTable(db.sales), r.readTable(db.saleLines))];
  }

  @override
  Future<void> softDelete(String id) async {
    await (db.update(db.sales)..where((s) => s.id.equals(id))).write(
      SalesCompanion(deleted: const Value(true), updatedAt: Value(clock.now())),
    );
    await touched(id);
  }
}
