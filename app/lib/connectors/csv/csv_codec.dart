import 'package:csv/csv.dart';

/// Reads and writes the CSV files the app exchanges with spreadsheets.
/// The first row is always a header; header names are matched
/// case-insensitively.
class CsvCodec {
  const CsvCodec();

  /// Rows as header -> value maps. Blank lines are skipped.
  List<Map<String, String>> parse(String text) {
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text.replaceAll('\r\n', '\n'));
    if (rows.isEmpty) return const [];
    final header = [for (final h in rows.first) h.toString().trim().toLowerCase()];
    return [
      for (final r in rows.skip(1))
        if (r.isNotEmpty && r.first.toString().trim().isNotEmpty)
          {
            for (var i = 0; i < header.length && i < r.length; i++)
              header[i]: r[i].toString().trim(),
          },
    ];
  }

  String write(List<List<Object?>> rows) => const ListToCsvConverter().convert(rows);

  /// Dollars as written in a file ("12.50", "$12.50") to cents.
  int cents(String? value) =>
      ((double.tryParse((value ?? '').replaceAll(r'$', '')) ?? 0) * 100).round();
}
