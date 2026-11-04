import '../connector.dart';
import 'csv_codec.dart';

/// Base for connectors that read a CSV file the user picked. Set
/// [pendingText] then call `ingest()`; with no text pending the run is a no-op.
/// The file is the whole source, so the cursor never moves and dedupe is
/// what makes re-importing the same file safe.
abstract class CsvImportConnector<TModel> extends Connector<Map<String, String>, TModel> {
  CsvImportConnector(super.cursors, {this.codec = const CsvCodec()});

  final CsvCodec codec;
  String? pendingText;

  @override
  Future<List<Map<String, String>>> fetch(String? cursor) async {
    final text = pendingText;
    pendingText = null;
    return text == null ? const [] : codec.parse(text);
  }
}
