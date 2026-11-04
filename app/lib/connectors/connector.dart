import 'ingest_result.dart';
import 'sync_cursor.dart';

/// Base for every data source the app reads from.
///
///   fetch (raw, since cursor) -> normalize -> sink (dedupe + store) -> advance cursor
///
/// A new source is one subclass. Each kind lives in its own folder with an
/// abstract base, the real implementation and a Fake* twin for offline dev
/// (file-based kinds such as CSV and ICS read local files, so they need no Fake).
/// The cursor only advances after a successful sink, so a failed run retries
/// the same window.
abstract class Connector<TRaw, TModel> {
  Connector(this.cursors);

  final SyncCursor cursors;

  /// Stable key for the cursor row.
  String get id;

  /// Raw records newer than [cursor] (null on the first run).
  Future<List<TRaw>> fetch(String? cursor);

  /// Map one raw record to our model.
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
