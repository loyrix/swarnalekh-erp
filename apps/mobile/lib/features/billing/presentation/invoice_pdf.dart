import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/shared/application/data_image.dart';

/// Fonts for the invoice PDF. Injected so the generator stays pure/testable —
/// the screen loads Noto Sans (+ Devanagari/Gujarati fallback) at runtime, and
/// tests can build with the built-in fonts.
class InvoicePdfFonts {
  const InvoicePdfFonts({this.base, this.bold, this.fallback = const []});

  final pw.Font? base;
  final pw.Font? bold;
  final List<pw.Font> fallback;

  bool get hasEmbeddedFonts => base != null && bold != null;
}

String _money(double v) => 'Rs. ${v.toStringAsFixed(2)}';
String _weight(double v) => '${v.toStringAsFixed(3)} g';
String _pct(double v) => '${v.toStringAsFixed(1)}%';

String _date(DateTime? value) {
  if (value == null) return '-';
  final d = value.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Builds a richly-laid-out, multi-page tax invoice PDF (shop header + logo,
/// item table, GST breakdown, payments, verification code + QR) from the
/// server's printable payload. Replaces the old hand-rolled text PDF.
Future<Uint8List> buildInvoicePdf(
  PrintableInvoice printable, {
  InvoicePdfFonts fonts = const InvoicePdfFonts(),
}) async {
  final theme = fonts.hasEmbeddedFonts
      ? pw.ThemeData.withFont(
          base: fonts.base!,
          bold: fonts.bold!,
          fontFallback: fonts.fallback,
        )
      : null;

  final doc = pw.Document(theme: theme);
  final inv = printable.invoice;
  final shop = printable.shop;

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
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        _header(shop, inv, logo),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        _billTo(inv),
        pw.SizedBox(height: 12),
        _itemsTable(inv),
        pw.SizedBox(height: 12),
        _totalsAndGst(inv),
        if (inv.payments.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _paymentsTable(inv),
        ],
        if (inv.notes != null) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            'Notes: ${inv.notes}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
        pw.SizedBox(height: 16),
        _protection(printable),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(
  PrintableShop shop,
  PrintableInvoiceDetail inv,
  pw.MemoryImage? logo,
) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (logo != null) ...[
        pw.Container(width: 54, height: 54, child: pw.Image(logo)),
        pw.SizedBox(width: 12),
      ],
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shop.name ?? 'SwarnaLekh',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            if (shop.address != null)
              pw.Text(
                shop.address!,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            pw.Wrap(
              spacing: 10,
              children: [
                if (shop.phone != null)
                  pw.Text(
                    'Phone: ${shop.phone}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (shop.gstin != null)
                  pw.Text(
                    'GSTIN: ${shop.gstin}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (shop.pan != null)
                  pw.Text(
                    'PAN: ${shop.pan}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 12),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'TAX INVOICE',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            inv.invoiceNumber ?? '-',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            _date(inv.invoiceDate),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _billTo(PrintableInvoiceDetail inv) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Bill To',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              inv.customerName ?? 'Walk-in Customer',
              style: const pw.TextStyle(fontSize: 11),
            ),
            if (inv.customerPhone != null)
              pw.Text(
                'Mobile: ${inv.customerPhone}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            if (inv.customerGstin != null)
              pw.Text(
                'GSTIN: ${inv.customerGstin}',
                style: const pw.TextStyle(fontSize: 9),
              ),
          ],
        ),
      ),
      if (inv.paymentMode != null)
        pw.Text(
          'Payment: ${inv.paymentMode}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
    ],
  );
}

pw.Widget _itemsTable(PrintableInvoiceDetail inv) {
  final headers = [
    'Item',
    'Purity',
    'Gross',
    'Net',
    'Rate',
    'Making',
    'Amount',
  ];
  final data = inv.items
      .map(
        (item) => [
          item.itemName ?? 'Item',
          item.karat ?? '-',
          _weight(item.grossWeight),
          _weight(item.netWeight),
          _money(item.ratePerGram),
          _money(item.makingCharges),
          _money(item.itemTotal),
        ],
      )
      .toList();

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    cellStyle: const pw.TextStyle(fontSize: 8),
    cellHeight: 18,
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.center,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerRight,
      5: pw.Alignment.centerRight,
      6: pw.Alignment.centerRight,
    },
  );
}

pw.Widget _totalsAndGst(PrintableInvoiceDetail inv) {
  final gstRows = <List<String>>[
    ['Taxable Amount', _money(inv.taxableAmount)],
    if (inv.cgstAmount > 0)
      ['CGST ${_pct(inv.cgstPercent)}', _money(inv.cgstAmount)],
    if (inv.sgstAmount > 0)
      ['SGST ${_pct(inv.sgstPercent)}', _money(inv.sgstAmount)],
    if (inv.igstAmount > 0)
      ['IGST ${_pct(inv.igstPercent)}', _money(inv.igstAmount)],
    ['Total GST', _money(inv.totalTax)],
  ];

  final billRows = <List<String>>[
    ['Gold Value', _money(inv.subtotal)],
    ['Making Charges', _money(inv.totalMakingCharges)],
    if (inv.totalStoneValue > 0) ['Stone Value', _money(inv.totalStoneValue)],
    if (inv.discountAmount > 0) ['Discount', '- ${_money(inv.discountAmount)}'],
    if (inv.oldGoldValue > 0) ['Old Gold', '- ${_money(inv.oldGoldValue)}'],
  ];

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: _summaryBox('GST Breakdown', gstRows)),
      pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Column(
          children: [
            _summaryBox('Bill Summary', billRows),
            pw.SizedBox(height: 6),
            _emphasisRow('Grand Total', _money(inv.grandTotal)),
            _plainRow('Amount Paid', _money(inv.amountPaid)),
            _plainRow('Balance Due', _money(inv.balanceDue)),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _summaryBox(String title, List<List<String>> rows) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...rows.map((r) => _plainRow(r[0], r[1])),
      ],
    ),
  );
}

pw.Widget _plainRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
      ],
    ),
  );
}

pw.Widget _emphasisRow(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
    color: PdfColors.grey200,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

pw.Widget _paymentsTable(PrintableInvoiceDetail inv) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Payments',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Mode', 'Reference', 'Amount'],
        data: inv.payments
            .map(
              (p) => [
                _date(p.paymentDate),
                p.paymentMode,
                p.referenceNumber ?? '-',
                _money(p.amount),
              ],
            )
            .toList(),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellHeight: 16,
        cellAlignments: {3: pw.Alignment.centerRight},
      ),
    ],
  );
}

pw.Widget _protection(PrintableInvoice printable) {
  final code = printable.verificationCode;
  final qr = printable.qrPayload;
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice Protection',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (code != null)
                pw.Text(
                  'Verification: $code',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              pw.Text(
                'Generated: ${_date(printable.generatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thank you for shopping with us.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        if (qr != null)
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: qr,
            width: 64,
            height: 64,
            drawText: false,
          ),
      ],
    ),
  );
}
