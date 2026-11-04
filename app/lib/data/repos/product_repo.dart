import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/database.dart';
import 'repository.dart';

class ProductRepo extends Repository<Product> {
  ProductRepo(super.db, super.tracker, super.deviceId);

  @override
  String get entity => 'products';

  @override
  Stream<List<Product>> watchAll({bool includeArchived = false}) {
    final q = db.select(db.products)
      ..where((p) => p.deleted.equals(false))
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    if (!includeArchived) q.where((p) => p.archived.equals(false));
    return q.watch();
  }

  @override
  Future<Product?> byId(String id) =>
      (db.select(db.products)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Live (not deleted, not archived) products, name order.
  Future<List<Product>> all() => watchAll().first;

  /// Case-insensitive name match among live products; the CSV import's dedupe key.
  Future<Product?> findByName(String name) async {
    final lower = name.trim().toLowerCase();
    for (final p in await all()) {
      if (p.name.toLowerCase() == lower) return p;
    }
    return null;
  }

  Future<String> save(ProductsCompanion data) async {
    final id = data.id.present ? data.id.value : makeId();
    final row = data.copyWith(
      id: Value(id),
      updatedAt: Value(DateTime.now()),
      deviceId: Value(deviceId),
    );
    await db.into(db.products).insertOnConflictUpdate(row);
    if (data.priceCents.present) await _recordPrice(id, data.priceCents.value);
    await touched(id);
    return id;
  }

  @override
  Future<void> softDelete(String id) async {
    await (db.update(db.products)..where((p) => p.id.equals(id))).write(
      ProductsCompanion(deleted: const Value(true), updatedAt: Value(DateTime.now())),
    );
    await touched(id, SyncOp.delete);
  }

  // ---- bill of materials ----

  Stream<List<BomLine>> watchBom(String productId) => (db.select(
    db.bomLines,
  )..where((b) => b.productId.equals(productId) & b.deleted.equals(false))).watch();

  Future<void> saveBomLine(BomLinesCompanion line) async {
    final id = line.id.present ? line.id.value : makeId();
    await db
        .into(db.bomLines)
        .insertOnConflictUpdate(
          line.copyWith(id: Value(id), updatedAt: Value(DateTime.now()), deviceId: Value(deviceId)),
        );
    await tracker.record('bom_lines', id, SyncOp.upsert);
  }

  /// BOM total when present, otherwise the manual unit cost.
  Future<int> unitCost(String productId) async {
    final bom = await (db.select(
      db.bomLines,
    )..where((b) => b.productId.equals(productId) & b.deleted.equals(false))).get();
    if (bom.isNotEmpty) {
      return bom.fold<int>(0, (sum, b) => sum + (b.costCents * b.qty).round());
    }
    return (await byId(productId))?.unitCostCents ?? 0;
  }

  Future<void> _recordPrice(String productId, int cents) async {
    final id = makeId();
    await db
        .into(db.priceHistory)
        .insert(
          PriceHistoryCompanion.insert(
            id: Value(id),
            productId: productId,
            priceCents: cents,
            deviceId: Value(deviceId),
          ),
        );
    await tracker.record('price_history', id, SyncOp.upsert);
  }
}
