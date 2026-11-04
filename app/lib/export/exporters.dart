import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/money.dart';
import 'exporter.dart';

class CsvExporter extends Exporter {
  @override
  ExportFormat get format => ExportFormat.csv;

  @override
  Future<Uint8List> encode(ExportRequest req) async {
    final rows = req.salesRows.isNotEmpty ? req.salesRows : req.productRows;
    return Uint8List.fromList(utf8.encode(const ListToCsvConverter().convert(rows)));
  }
}

class PngExporter extends Exporter {
  @override
  ExportFormat get format => ExportFormat.png;

  @override
  Future<Uint8List> encode(ExportRequest req) async =>
      req.pngBytes ?? (throw ArgumentError('PNG export needs pngBytes'));
}

/// Workbook: Summary, Sales, Per product, Inventory.
class XlsxExporter extends Exporter {
  @override
  ExportFormat get format => ExportFormat.xlsx;

  CellValue? _cell(Object? v) => switch (v) {
    null => null,
    int i => IntCellValue(i),
    double d => DoubleCellValue(d),
    DateTime t => DateTimeCellValue.fromDateTime(t),
    _ => TextCellValue(v.toString()),
  };

  void _sheet(Excel x, String name, List<List<Object?>> rows) {
    if (rows.isEmpty) return;
    final s = x[name];
    for (final r in rows) {
      s.appendRow([for (final v in r) _cell(v)]);
    }
  }

  @override
  Future<Uint8List> encode(ExportRequest req) async {
    final x = Excel.createExcel();
    final r = req.report;
    if (r != null) {
      _sheet(x, 'Summary', [
        ['Metric', 'Value'],
        ['Gross', r.grossCents / 100],
        ['Cost', r.costCents / 100],
        ['Booth fee', r.boothFeeCents / 100],
        ['Net', r.netCents / 100],
        ['Units', r.units],
      ]);
      _sheet(x, 'Per product', [
        ['Item', 'Units', 'Gross', 'Cost', 'Profit', 'Margin', 'First sold', 'Last sold'],
        for (final p in r.ranked)
          [
            p.name,
            p.units,
            p.grossCents / 100,
            p.costCents / 100,
            p.profitCents / 100,
            p.margin,
            p.firstSold,
            p.lastSold,
          ],
      ]);
    }
    _sheet(x, 'Sales', req.salesRows);
    _sheet(x, 'Inventory', req.inventoryRows);
    x.delete('Sheet1');
    return Uint8List.fromList(x.save()!);
  }
}

/// Branded post-event report.
class PdfReportExporter extends Exporter {
  PdfReportExporter({required this.shopName});

  final String shopName;

  @override
  ExportFormat get format => ExportFormat.pdf;

  @override
  Future<Uint8List> encode(ExportRequest req) async {
    final r = req.report;
    final doc = pw.Document(title: req.title, author: shopName);
    const ink = PdfColor.fromInt(0xFF17131F);
    const cobalt = PdfColor.fromInt(0xFF2F5BFF);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (_) => [
          pw.Text(shopName.toUpperCase(), style: const pw.TextStyle(fontSize: 10, color: ink)),
          pw.SizedBox(height: 4),
          pw.Text(
            req.title,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: ink),
          ),
          pw.SizedBox(height: 16),
          if (r != null) ...[
            pw.Text(
              Money.signed(r.netCents),
              style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: cobalt),
            ),
            pw.Text(
              '${Money.format(r.grossCents)} gross, ${Money.format(r.costCents)} cost, '
              '${Money.format(r.boothFeeCents)} booth. ${r.units} sold.',
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Units', 'Gross', 'Profit', 'Margin'],
              data: [
                for (final p in r.ranked)
                  [
                    p.name,
                    '${p.units}',
                    Money.format(p.grossCents),
                    Money.signed(p.profitCents),
                    '${(p.margin * 100).round()}%',
                  ],
              ],
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
