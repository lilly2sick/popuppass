import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/domain/analytics_service.dart';
import 'package:popup_pass/domain/enums.dart';
import 'package:popup_pass/export/exporter.dart';
import 'package:popup_pass/export/exporters.dart';

void main() {
  final report = EventReport(boothFeeCents: 12000)
    ..grossCents = 4200
    ..costCents = 900
    ..units = 6;
  report.byProduct['p1'] = ProductStats('p1', 'Cat sticker')
    ..units = 6
    ..grossCents = 4200
    ..costCents = 900;
  report.byMethod[PaymentMethod.cash] = 4200;

  final request = ExportRequest(
    title: 'Test report',
    report: report,
    salesRows: [
      ['Item', 'Qty'],
      ['Cat sticker', 6],
    ],
    productRows: [
      ['name', 'price'],
      ['Cat sticker', '7.00'],
    ],
    inventoryRows: [
      ['Item', 'On hand'],
      ['Cat sticker', 4],
    ],
    pngBytes: Uint8List.fromList(const [137, 80, 78, 71]),
  );

  final exporters = <Exporter>[
    CsvExporter(),
    PngExporter(),
    XlsxExporter(),
    PdfReportExporter(shopName: 'Mochi Paws'),
  ];

  for (final e in exporters) {
    test('${e.format.label} export is non-empty', () async {
      expect(await e.encode(request), isNotEmpty);
    });
  }

  test('CSV carries the header and rows', () async {
    final text = utf8.decode(await CsvExporter().encode(request));
    expect(text, contains('Item,Qty'));
    expect(text, contains('Cat sticker,6'));
  });

  test('XLSX is a zip and PDF starts with %PDF', () async {
    final xlsx = await XlsxExporter().encode(request);
    expect(xlsx.sublist(0, 2), [0x50, 0x4B]);
    final pdf = await PdfReportExporter(shopName: 'Mochi Paws').encode(request);
    expect(ascii.decode(pdf.sublist(0, 4)), '%PDF');
  });

  test('PNG export without bytes is an error', () {
    expect(() => PngExporter().encode(const ExportRequest(title: 't')), throwsArgumentError);
  });
}
