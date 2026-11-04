import 'package:share_plus/share_plus.dart';

import '../services/entitlements.dart';
import 'exporter.dart';
import 'exporters.dart';

class ExportLocked implements Exception {
  const ExportLocked(this.format);
  final ExportFormat format;
}

/// Picks the exporter, applies plan gates, hands the file to the share sheet.
class ExportService {
  ExportService({required this.entitlements, required String shopName})
      : _exporters = {
          ExportFormat.csv: CsvExporter(),
          ExportFormat.png: PngExporter(),
          ExportFormat.xlsx: XlsxExporter(),
          ExportFormat.pdf: PdfReportExporter(shopName: shopName),
        };

  final Entitlements Function() entitlements;
  final Map<ExportFormat, Exporter> _exporters;

  bool allowed(ExportFormat f) => f.gate == null || entitlements().can(f.gate!);

  Future<void> share(ExportFormat f, ExportRequest req) async {
    if (!allowed(f)) throw ExportLocked(f);
    final file = await _exporters[f]!.export(req);
    await Share.shareXFiles([XFile(file.path)], subject: req.title);
  }
}
