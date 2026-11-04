import 'package:drift/drift.dart';

import '../data/db/database.dart';

class IngestResult {
  const IngestResult({required this.fetched, required this.added, this.error});

  final int fetched;
  final int added;
  final Object? error;

  bool get ok => error == null;
}

/// Where each connector remembers how far it has read.
class CursorStore {
  CursorStore(this.db);

  final AppDatabase db;

  Future<String?> read(String connectorId) async =>
      (await (db.select(db.connectorCursors)..where((c) => c.connectorId.equals(connectorId))).getSingleOrNull())
          ?.cursor;

  Future<void> write(String connectorId, String? cursor) => db.into(db.connectorCursors).insertOnConflictUpdate(
        ConnectorCursorsCompanion.insert(
          connectorId: connectorId,
          cursor: Value(cursor),
          lastRunAt: Value(DateTime.now()),
        ),
      );
}

/// Base for every data source the app reads from.
///
///   fetch (raw, since cursor) -> normalize -> sink (dedupe + store) -> advance cursor
///
/// A new source is one subclass. Each has a Fake* twin for offline dev.
abstract class Connector<TRaw, TModel> {
  Connector(this.cursors);

  final CursorStore cursors;

  String get id;

  Future<List<TRaw>> fetch(String? cursor);

  TModel normalize(TRaw raw);

  /// Store models, deduping on (source, externalId). Returns rows added.
  Future<int> sink(List<TModel> models);

  /// Cursor to persist after a successful run. Default: unchanged.
  String? nextCursor(List<TRaw> raws, String? previous) => previous;

  Future<IngestResult> ingest() async {
    try {
      final cursor = await cursors.read(id);
      final raws = await fetch(cursor);
      final added = await sink(raws.map(normalize).toList());
      await cursors.write(id, nextCursor(raws, cursor));
      return IngestResult(fetched: raws.length, added: added);
    } catch (e) {
      return IngestResult(fetched: 0, added: 0, error: e);
    }
  }
}
