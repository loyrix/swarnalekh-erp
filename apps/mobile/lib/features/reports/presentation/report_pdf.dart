import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:swarnbook/features/reports/presentation/report_pdf_tables.dart';
import 'package:swarnbook/shared/application/data_image.dart';

/// Shop identity for the report letterhead. Mirrors the invoice letterhead so
/// every document the shop hands out looks like it came from the same house.
class ReportPdfShop {
  const ReportPdfShop({
    this.name,
    this.address,
    this.phone,
    this.gstin,
    this.pan,
    this.logoUrl,
  });

  final String? name;
  final String? address;
  final String? phone;
  final String? gstin;
  final String? pan;
  final String? logoUrl;
}

/// Fonts for the report PDF. Injected so the generator stays pure/testable —
/// the screen loads Noto Sans (+ Devanagari/Gujarati fallback) at runtime, and
/// tests can build with the built-in fonts.
class ReportPdfFonts {
  const ReportPdfFonts({this.base, this.bold, this.fallback = const []});

  final pw.Font? base;
  final pw.Font? bold;
  final List<pw.Font> fallback;

  bool get hasEmbeddedFonts => base != null && bold != null;
}

// Letterhead palette — shared with the invoice PDF (deep antique gold).
final PdfColor _gold = PdfColor.fromHex('#8A6A1F');
final PdfColor _goldWash = PdfColor.fromHex('#F5EEDC');
final PdfColor _ink = PdfColor.fromHex('#221C10');
final PdfColor _mutedInk = PdfColor.fromHex('#6A6252');
final PdfColor _hairline = PdfColor.fromHex('#D8CFB8');
final PdfColor _zebra = PdfColor.fromHex('#FAF7EF');

String _generatedOn(DateTime value) {
  final d = value.toLocal();
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}  $hh:$mm';
}

/// Builds a professional, print-ready report PDF: the shop letterhead, a
/// titled banner with an optional summary line, a ruled/zebra table that
/// paginates across pages with a repeating header, and an emphasised total
/// row. Renders an empty-state note when the table has no rows.
Future<Uint8List> buildReportPdf({
  required ReportPdfShop shop,
  required ReportPdfTable table,
  DateTime? generatedAt,
  ReportPdfFonts fonts = const ReportPdfFonts(),
}) async {
  final theme = fonts.hasEmbeddedFonts
      ? pw.ThemeData.withFont(
          base: fonts.base!,
          bold: fonts.bold!,
          fontFallback: fonts.fallback,
        )
      : null;

  final doc = pw.Document(theme: theme);
  final stamp = generatedAt ?? DateTime.now();

  pw.MemoryImage? logo;
  final logoUrl = shop.logoUrl;
  if (logoUrl != null && isDataImage(logoUrl)) {
    try {
      logo = pw.MemoryImage(decodeDataImage(logoUrl));
    } catch (_) {
      logo = null;
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 30),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: _hairline, height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                shop.name ?? 'SwarnaLekh',
                style: pw.TextStyle(fontSize: 7.5, color: _mutedInk),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7.5, color: _mutedInk),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        _letterhead(shop, logo),
        pw.SizedBox(height: 10),
        _banner(table.title),
        pw.SizedBox(height: 6),
        _metaLine(table.summary, stamp),
        pw.SizedBox(height: 10),
        if (table.rows.isEmpty) _emptyNote() else _table(table),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _letterhead(ReportPdfShop shop, pw.MemoryImage? logo) {
  final contact = [
    if (shop.address != null && shop.address!.trim().isNotEmpty) shop.address!,
    if (shop.phone != null && shop.phone!.trim().isNotEmpty)
      'Ph: ${shop.phone}',
  ].join('  ·  ');
  final tax = [
    if (shop.gstin != null && shop.gstin!.trim().isNotEmpty)
      'GSTIN: ${shop.gstin}',
    if (shop.pan != null && shop.pan!.trim().isNotEmpty) 'PAN: ${shop.pan}',
  ].join('    ');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(width: 52, height: 52, child: pw.Image(logo))
          else
            pw.SizedBox(width: 52),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  shop.name ?? 'SwarnaLekh',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _gold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (contact.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      contact,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
                    ),
                  ),
                if (tax.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      tax,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 52),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 2, color: _gold),
      pw.SizedBox(height: 1.5),
      pw.Container(height: 0.7, color: _gold),
    ],
  );
}

pw.Widget _banner(String title) {
  return pw.Center(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _goldWash,
        border: pw.Border.all(color: _gold, width: 0.7),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _gold,
          letterSpacing: 1.5,
        ),
      ),
    ),
  );
}

pw.Widget _metaLine(String? summary, DateTime stamp) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Expanded(
        child: pw.Text(
          summary ?? '',
          style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
        ),
      ),
      pw.Text(
        'Generated: ${_generatedOn(stamp)}',
        style: pw.TextStyle(fontSize: 8, color: _mutedInk),
      ),
    ],
  );
}

pw.Widget _emptyNote() {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 26),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _hairline, width: 0.7),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Center(
      child: pw.Text(
        'No records for the selected filters.',
        style: pw.TextStyle(fontSize: 10, color: _mutedInk),
      ),
    ),
  );
}

pw.Widget _table(ReportPdfTable table) {
  final columnWidths = <int, pw.TableColumnWidth>{
    for (var i = 0; i < table.columns.length; i++)
      i: pw.FlexColumnWidth(table.columns[i].flex.toDouble()),
  };

  pw.Widget cell(
    String text, {
    required bool numeric,
    required bool header,
    bool emphasise = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: numeric ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: header ? 8 : 8.5,
          fontWeight: header || emphasise
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: header ? PdfColors.white : _ink,
          letterSpacing: header ? 0.3 : 0,
        ),
      ),
    );
  }

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: _gold),
      children: [
        for (final col in table.columns)
          cell(col.label, numeric: col.numeric, header: true),
      ],
    ),
    for (var r = 0; r < table.rows.length; r++)
      pw.TableRow(
        decoration: pw.BoxDecoration(color: r.isOdd ? _zebra : PdfColors.white),
        children: [
          for (var c = 0; c < table.columns.length; c++)
            cell(
              c < table.rows[r].length ? table.rows[r][c] : '',
              numeric: table.columns[c].numeric,
              header: false,
            ),
        ],
      ),
    if (table.totalRow != null)
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _goldWash),
        children: [
          for (var c = 0; c < table.columns.length; c++)
            cell(
              c < table.totalRow!.length ? table.totalRow![c] : '',
              numeric: table.columns[c].numeric,
              header: false,
              emphasise: true,
            ),
        ],
      ),
  ];

  return pw.Table(
    columnWidths: columnWidths,
    border: pw.TableBorder.all(color: _hairline, width: 0.5),
    children: rows,
  );
}
