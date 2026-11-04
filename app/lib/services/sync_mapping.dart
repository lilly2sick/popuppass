import 'dart:convert';

/// Row shape translation between local SQLite and the Postgres tables.
class SyncMapping {
  const SyncMapping._();

  static const _boolCols = {'deleted', 'archived'};
  static const _jsonCols = {'tags', 'photo_paths', 'colors', 'niche_tags'};

  // Drift stores DateTime as unix seconds and bool as 0/1 by default.
  static Map<String, dynamic> toCloud(Map<String, dynamic> row) => {
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

  static Map<String, Object?> toLocal(Map<String, dynamic> row) => {
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
