import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/analytics_service.dart';
import '../services/entitlements.dart';

enum ExportFormat {
  csv('csv', 'CSV'),
  png('png', 'PNG'),
  xlsx('xlsx', 'Excel'),
  pdf('pdf', 'PDF report');

  const ExportFormat(this.ext, this.label);
  final String ext;
  final String label;

  /// Free: CSV and PNG. Pro: branded PDF and XLSX.
  Feature? get gate => switch (this) {
        ExportFormat.pdf => Feature.exportPdf,
        ExportFormat.xlsx => Feature.exportXlsx,
        _ => null,
      };
}

/// What to export. Exporters read whatever fields they need.
class ExportRequest {
  const ExportRequest({
    required this.title,
    this.report,
    this.salesRows = const [],
    this.productRows = const [],
    this.inventoryRows = const [],
    this.pngBytes,
  });

  final String title;
  final EventReport? report;

  /// Pre-flattened tables: first row is the header.
  final List<List<Object?>> salesRows;
  final List<List<Object?>> productRows;
  final List<List<Object?>> inventoryRows;

  /// For PNG: bytes captured from a RepaintBoundary (see render/capture.dart).
  final Uint8List? pngBytes;
}

/// Base for every export format. Everything happens on device.
abstract class Exporter {
  ExportFormat get format;

  Future<Uint8List> encode(ExportRequest req);

  Future<File> export(ExportRequest req) async {
    final dir = await getTemporaryDirectory();
    final safe = req.title.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-').toLowerCase();
    final file = File('${dir.path}/$safe.${format.ext}');
    return file.writeAsBytes(await encode(req), flush: true);
  }
}
