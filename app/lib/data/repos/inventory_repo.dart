import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/database.dart';
import 'repository.dart';

/// Stock is never stored, only derived: SUM(delta) over the moves ledger.
class InventoryRepo extends Repository<InventoryMove> {
  InventoryRepo(super.db, super.tracker, super.deviceId);

  @override
  String get entity => 'inventory_moves';

  @override
  Stream<List<InventoryMove>> watchAll() =>
      (db.select(db.inventoryMoves)..where((m) => m.deleted.equals(false))).watch();

  @override
  Future<InventoryMove?> byId(String id) =>
      (db.select(db.inventoryMoves)..where((m) => m.id.equals(id))).getSingleOrNull();

  /// productId -> units on hand.
  Stream<Map<String, int>> watchStock() => db
      .customSelect(
        'SELECT product_id, SUM(delta) AS qty FROM inventory_moves WHERE deleted = 0 GROUP BY product_id',
        readsFrom: {db.inventoryMoves},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('product_id'): r.read<int>('qty')});

  Future<void> move({
    required String productId,
    required int delta,
    required MoveReason reason,
    String? eventId,
    String? saleLineId,
  }) async {
    final id = makeId();
    await db
        .into(db.inventoryMoves)
        .insert(
          InventoryMovesCompanion.insert(
            id: Value(id),
            productId: productId,
            delta: delta,
            reason: reason,
            eventId: Value(eventId),
            saleLineId: Value(saleLineId),
            deviceId: Value(deviceId),
          ),
        );
    await touched(id);
  }

  Future<void> restock(String productId, int qty, {String? eventId}) =>
      move(productId: productId, delta: qty, reason: MoveReason.restock, eventId: eventId);

  /// Ledger rows are not deleted on device; a correction is a new move.
  @override
  Future<void> softDelete(String id) => throw UnsupportedError('Use an adjust move instead');
}
