import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/db/database.dart';
import '../data/repos/repository.dart';
import '../domain/enums.dart';

/// Pro cloud backup. Implements [ChangeTracker] so every repository write
/// lands in the outbox; [push] uploads it.
///
/// Conflict model: ledgers (sales, sale_lines, inventory_moves, price_history)
/// are append-only so they never conflict. Editable rows are last-write-wins
/// on updated_at. The server enforces ownership with RLS; user_id defaults
/// to auth.uid() and is never sent.
class SyncService implements ChangeTracker {
  SyncService(this.db, this.client, {required this.isPro});

  final AppDatabase db;
  final SupabaseClient client;
  final bool Function() isPro;

  /// Push order respects foreign keys.
  static const entities = [
    'events',
    'products',
    'brands',
    'bom_lines',
    'price_history',
    'sales',
    'sale_lines',
    'inventory_moves',
  ];

  static const _boolCols = {'deleted', 'archived'};
  static const _jsonCols = {'tags', 'photo_paths', 'colors', 'niche_tags'};

  @override
  Future<void> record(String entity, String rowId, SyncOp op) async {
    if (!isPro()) return;
    await db
        .into(db.syncOutbox)
        .insert(SyncOutboxCompanion.insert(entity: entity, rowId: rowId, op: op));
  }

  /// First time someone goes Pro: queue every existing row.
  Future<void> backfill() async {
    for (final e in entities) {
      final ids = await db.customSelect('SELECT id FROM $e').get();
      await db.batch(
        (b) => b.insertAll(db.syncOutbox, [
          for (final r in ids)
            SyncOutboxCompanion.insert(entity: e, rowId: r.read<String>('id'), op: SyncOp.upsert),
        ]),
      );
    }
  }

  Future<int> pendingCount() async => (await db.select(db.syncOutbox).get()).length;

  Future<void> push({int batchSize = 200}) async {
    if (!isPro() || client.auth.currentUser == null) return;
    final pending =
        await (db.select(db.syncOutbox)
              ..orderBy([(o) => OrderingTerm.asc(o.seq)])
              ..limit(batchSize))
            .get();
    if (pending.isEmpty) return;

    final byEntity = <String, Set<String>>{};
    for (final p in pending) {
      byEntity.putIfAbsent(p.entity, () => {}).add(p.rowId);
    }
    for (final entity in entities.where(byEntity.containsKey)) {
      final ids = byEntity[entity]!.toList();
      final rows = await db
          .customSelect(
            'SELECT * FROM $entity WHERE id IN (${List.filled(ids.length, '?').join(',')})',
            variables: [for (final id in ids) Variable.withString(id)],
          )
          .get();
      await client.from(entity).upsert([for (final r in rows) _toCloud(r.data)]);
    }
    await (db.delete(
      db.syncOutbox,
    )..where((o) => o.seq.isSmallerOrEqualValue(pending.last.seq))).go();
  }

  /// New device: pull everything for this user and write it locally.
  Future<void> restore() async {
    for (final entity in entities) {
      final rows = await client.from(entity).select();
      await db.transaction(() async {
        for (final r in rows) {
          final local = _toLocal(r);
          final cols = local.keys.toList();
          await db.customStatement(
            'INSERT OR REPLACE INTO $entity (${cols.join(',')}) VALUES (${List.filled(cols.length, '?').join(',')})',
            [for (final c in cols) local[c]],
          );
        }
      });
    }
  }

  // Drift stores DateTime as unix seconds and bool as 0/1 by default.
  Map<String, dynamic> _toCloud(Map<String, dynamic> row) => {
    for (final e in row.entries)
      e.key: switch (e.key) {
        final k when _boolCols.contains(k) => e.value == 1,
        final k when _jsonCols.contains(k) => jsonDecode(e.value as String),
        final k when (k.endsWith('_at') || k == 'at') && e.value is int =>
          DateTime.fromMillisecondsSinceEpoch(
            (e.value as int) * 1000,
            isUtc: true,
          ).toIso8601String(),
        _ => e.value,
      },
  };

  Map<String, Object?> _toLocal(Map<String, dynamic> row) => {
    for (final e in row.entries)
      if (e.key != 'user_id')
        e.key: switch (e.key) {
          final k when _boolCols.contains(k) => (e.value == true) ? 1 : 0,
          final k when _jsonCols.contains(k) => jsonEncode(e.value),
          final k when (k.endsWith('_at') || k == 'at') && e.value is String =>
            DateTime.parse(e.value as String).millisecondsSinceEpoch ~/ 1000,
          _ => e.value,
        },
  };
}
