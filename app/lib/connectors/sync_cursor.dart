import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../data/db/database.dart';

/// Where each connector remembers how far it has read. One row per connector
/// id in `connector_cursors`; the cursor string is opaque to everything but
/// the connector that wrote it (a timestamp, a snapshot version, a page token).
class SyncCursor {
  SyncCursor(this.db);

  final AppDatabase db;

  Future<String?> read(String connectorId) async => (await (db.select(
    db.connectorCursors,
  )..where((c) => c.connectorId.equals(connectorId))).getSingleOrNull())?.cursor;

  Future<void> write(String connectorId, String? cursor) => db
      .into(db.connectorCursors)
      .insertOnConflictUpdate(
        ConnectorCursorsCompanion.insert(
          connectorId: connectorId,
          cursor: Value(cursor),
          lastRunAt: Value(clock.now()),
        ),
      );
}
