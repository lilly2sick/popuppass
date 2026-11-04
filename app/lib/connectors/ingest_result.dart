/// Outcome of one connector run. Connectors never throw out of `ingest`;
/// failures come back in [error] so callers can show a message and retry.
class IngestResult {
  const IngestResult({required this.fetched, required this.added, this.error});

  /// Raw records the source returned.
  final int fetched;

  /// Records that were new after deduping on (source, externalId).
  final int added;
  final Object? error;

  bool get ok => error == null;
}
