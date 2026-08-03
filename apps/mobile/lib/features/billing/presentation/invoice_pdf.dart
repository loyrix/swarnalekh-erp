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

// Navy-and-gold letterhead palette. Navy carries the structural blocks (table
// headers, footer band) and gold the accents, which is what gives the bill its
// weight in print without relying on large flat fills of colour.
final PdfColor _navy = PdfColor.fromHex('#16233F');
final PdfColor _gold = PdfColor.fromHex('#A8863C');
final PdfColor _goldDeep = PdfColor.fromHex('#8A6A1F');
final PdfColor _goldWash = PdfColor.fromHex('#F7F1E1');
final PdfColor _ink = PdfColor.fromHex('#221C10');
final PdfColor _mutedInk = PdfColor.fromHex('#6A6252');
final PdfColor _hairline = PdfColor.fromHex('#D8CFB8');

/// Brand strip printed along the foot of every page.
///
/// Separated with a middot (U+00B7) rather than a bullet (U+2022): the middot
/// is in the standard PDF encoding, so it still renders if the embedded Noto
/// fonts fail to load and the document falls back to Helvetica.
const String _brandStrip = 'SWARN LEKH   ·   PRECISION IN GOLD, TRUST FOR LIFE';

String _money(double v) => 'Rs. ${v.toStringAsFixed(2)}';
String _weight(double v) => '${v.toStringAsFixed(3)} g';
String _pct(double v) => '${v.toStringAsFixed(1)}%';

String _date(DateTime? value) {
  if (value == null) return '-';
  final d = value.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// 12-hour clock line printed under the invoice date. Null when there's no
/// timestamp to show.
String? _time(DateTime? value) {
  if (value == null) return null;
  final d = value.toLocal();
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '$hour12:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}

const List<String> _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];
const List<String> _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _twoDigits(int n) {
  if (n < 20) return _ones[n];
  final t = _tens[n ~/ 10];
  final o = n % 10;
  return o == 0 ? t : '$t ${_ones[o]}';
}

String _threeDigits(int n) {
  final h = n ~/ 100;
  final rest = n % 100;
  final parts = <String>[
    if (h > 0) '${_ones[h]} Hundred',
    if (rest > 0) _twoDigits(rest),
  ];
  return parts.join(' ');
}

/// Amount in words using the Indian numbering system (crore / lakh /
/// thousand), e.g. 184741.50 → "Rupees One Lakh Eighty Four Thousand Seven
/// Hundred Forty One and Paise Fifty Only".
String amountInWordsIndian(double amount) {
  final total = (amount.abs() * 100).round();
  final rupees = total ~/ 100;
  final paise = total % 100;
  if (rupees == 0 && paise == 0) return 'Rupees Zero Only';

  var n = rupees;
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;

  final words = <String>[
    if (crore > 0) '${_twoDigits(crore)} Crore',
    if (lakh > 0) '${_twoDigits(lakh)} Lakh',
    if (thousand > 0) '${_twoDigits(thousand)} Thousand',
    if (n > 0) _threeDigits(n),
  ];

  final rupeePart = words.isEmpty ? 'Zero' : words.join(' ');
  final paisePart = paise > 0 ? ' and Paise ${_twoDigits(paise)}' : '';
  return 'Rupees $rupeePart$paisePart Only';
}

/// Builds the customer-facing tax invoice PDF: navy-and-gold letterhead with
/// the shop's identity, invoice meta, itemised table (purity, weights, rate,
/// making), GST split, amount in words, payments, declaration, signature
/// blocks, and the brand footer band. Handles missing shop-profile fields
/// gracefully.
///
/// The verification code and QR are intentionally not printed — they remain on
/// [PrintableInvoice] for in-app use.
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
      margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 30),
      // Page numbering only carries on multi-page bills; a single-page invoice
      // ends on the brand band instead of a stray "Page 1 of 1".
      footer: (context) => context.pagesCount <= 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Row(
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
            ),
      build: (context) => [
        _letterhead(shop, logo),
        pw.SizedBox(height: 10),
        _invoiceBanner(),
        pw.SizedBox(height: 10),
        _metaGrid(inv),
        pw.SizedBox(height: 12),
        _itemsTable(inv),
        pw.SizedBox(height: 12),
        _totalsAndGst(inv),
        pw.SizedBox(height: 10),
        _amountInWords(inv),
        if (inv.payments.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _paymentsTable(inv),
        ],
        if (inv.notes != null) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Notes: ${inv.notes}',
            style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
          ),
        ],
        pw.SizedBox(height: 14),
        _declaration(printable),
        pw.SizedBox(height: 16),
        _thankYou(),
        pw.SizedBox(height: 14),
        _signatures(shop),
        pw.SizedBox(height: 18),
        _contactFooter(shop),
      ],
    ),
  );

  return doc.save();
}

/// Letterhead: framed logo at the left, shop name and city centred between
/// ornamental rules, GSTIN/PAN underneath, closed by a gold double rule.
pw.Widget _letterhead(PrintableShop shop, pw.MemoryImage? logo) {
  final tax = [
    if (shop.gstin != null) 'GSTIN: ${shop.gstin}',
    if (shop.pan != null) 'PAN: ${shop.pan}',
  ].join('     ');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Framed logo plate — navy card with a gold keyline, as in the mock.
          if (logo != null)
            pw.Container(
              width: 62,
              height: 62,
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                color: _navy,
                border: pw.Border.all(color: _gold, width: 1.2),
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            )
          else
            pw.SizedBox(width: 62),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Column(
                children: [
                  pw.Text(
                    (shop.name ?? 'SwarnaLekh').toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: _gold,
                      letterSpacing: 3,
                    ),
                  ),
                  if (shop.city != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1),
                      child: pw.Text(
                        shop.city!.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: _mutedInk,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 5),
                  _ornamentRule(),
                  if (tax.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
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
          ),
          pw.SizedBox(width: 62),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 2, color: _gold),
      pw.SizedBox(height: 1.5),
      pw.Container(height: 0.7, color: _gold),
    ],
  );
}

/// A hairline broken by a small diamond, the divider used under the shop name.
pw.Widget _ornamentRule() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Expanded(child: pw.Container(height: 0.7, color: _gold)),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5),
        child: pw.Transform.rotate(
          angle: 0.785398, // 45° — a square on its corner reads as a diamond.
          child: pw.Container(width: 4, height: 4, color: _gold),
        ),
      ),
      pw.Expanded(child: pw.Container(height: 0.7, color: _gold)),
    ],
  );
}

pw.Widget _invoiceBanner() {
  return pw.Center(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 34, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _gold,
        borderRadius: pw.BorderRadius.circular(11),
      ),
      child: pw.Text(
        'TAX INVOICE',
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 2.4,
        ),
      ),
    ),
  );
}

/// Two-column meta block: Bill To on the left, invoice particulars on the
/// right, in a single hairline frame.
pw.Widget _metaGrid(PrintableInvoiceDetail inv) {
  pw.Widget label(String s) => pw.Text(
    s,
    style: pw.TextStyle(fontSize: 7.5, color: _mutedInk, letterSpacing: 0.6),
  );
  pw.Widget value(String s, {double size = 10}) => pw.Text(
    s,
    style: pw.TextStyle(
      fontSize: size,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    ),
  );

  pw.Widget divider() => pw.Container(width: 0.7, height: 42, color: _hairline);

  pw.Widget cell(String heading, List<pw.Widget> body, {int flex = 1}) =>
      pw.Expanded(
        flex: flex,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [label(heading), pw.SizedBox(height: 3), ...body],
          ),
        ),
      );

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _hairline, width: 0.7),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    padding: const pw.EdgeInsets.symmetric(vertical: 10),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        cell('BILLED TO', [
          value(inv.customerName ?? 'Walk-in Customer', size: 12),
          if (inv.customerPhone != null)
            pw.Text(
              'Mobile: ${inv.customerPhone}',
              style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
            ),
          if (inv.customerAddress != null)
            pw.Text(
              inv.customerAddress!,
              style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
            ),
          if (inv.customerGstin != null)
            pw.Text(
              'GSTIN: ${inv.customerGstin}',
              style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
            ),
        ], flex: 2),
        divider(),
        cell('INVOICE NO', [value(inv.invoiceNumber ?? '-')]),
        divider(),
        cell('DATE', [
          value(_date(inv.invoiceDate)),
          if (_time(inv.invoiceDate) != null)
            pw.Text(
              _time(inv.invoiceDate)!,
              style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
            ),
        ]),
        divider(),
        cell('PAYMENT MODE', [value((inv.paymentMode ?? '-').toUpperCase())]),
      ],
    ),
  );
}

pw.Widget _itemsTable(PrintableInvoiceDetail inv) {
  final headers = [
    '#',
    'Description',
    'Purity',
    'Gross Wt',
    'Net Wt',
    'Rate / g',
    'Making',
    'Amount',
  ];
  final data = <List<String>>[];
  for (var i = 0; i < inv.items.length; i++) {
    final item = inv.items[i];
    data.add([
      '${i + 1}',
      item.itemName ?? 'Item',
      item.karat ?? '-',
      _weight(item.grossWeight),
      _weight(item.netWeight),
      item.ratePerGram > 0 ? _money(item.ratePerGram) : '-',
      _money(item.makingCharges),
      _money(item.itemTotal),
    ]);
  }

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    border: pw.TableBorder.all(color: _hairline, width: 0.5),
    headerStyle: pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      letterSpacing: 0.4,
    ),
    headerDecoration: pw.BoxDecoration(color: _navy),
    oddRowDecoration: pw.BoxDecoration(color: _goldWash),
    cellStyle: pw.TextStyle(fontSize: 8, color: _ink),
    cellHeight: 20,
    columnWidths: {
      0: const pw.FixedColumnWidth(16),
      1: const pw.FlexColumnWidth(3),
    },
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.center,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerRight,
      5: pw.Alignment.centerRight,
      6: pw.Alignment.centerRight,
      7: pw.Alignment.centerRight,
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
    ['Metal Value', _money(inv.subtotal)],
    ['Making Charges', _money(inv.totalMakingCharges)],
    if (inv.totalStoneValue > 0) ['Stone Value', _money(inv.totalStoneValue)],
    if (inv.discountAmount > 0) ['Discount', '- ${_money(inv.discountAmount)}'],
    if (inv.oldGoldValue > 0) ['Old Gold', '- ${_money(inv.oldGoldValue)}'],
  ];

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: _summaryBox('GST BREAKDOWN', gstRows)),
      pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Column(
          children: [
            _summaryBox('BILL SUMMARY', billRows),
            pw.SizedBox(height: 6),
            _grandTotalRow('GRAND TOTAL', _money(inv.grandTotal)),
            _plainRow('Amount Paid', _money(inv.amountPaid)),
            _plainRow('Balance Due', _money(inv.balanceDue)),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _amountInWords(PrintableInvoiceDetail inv) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _hairline, width: 0.7),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(fontSize: 8.5, color: _mutedInk),
        children: [
          const pw.TextSpan(text: 'Amount in words:  '),
          pw.TextSpan(
            text: amountInWordsIndian(inv.grandTotal),
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _summaryBox(String title, List<List<String>> rows) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _hairline, width: 0.7),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _gold,
            letterSpacing: 0.8,
          ),
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
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: _mutedInk)),
        pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: _ink)),
      ],
    ),
  );
}

pw.Widget _grandTotalRow(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    decoration: pw.BoxDecoration(
      color: _goldWash,
      border: pw.Border.all(color: _gold, width: 0.8),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _gold,
            letterSpacing: 0.8,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
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
        'PAYMENTS',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _gold,
          letterSpacing: 0.8,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Mode', 'Reference', 'Amount'],
        data: inv.payments
            .map(
              (p) => [
                _date(p.paymentDate),
                _titleCase(p.paymentMode),
                p.referenceNumber ?? '-',
                _money(p.amount),
              ],
            )
            .toList(),
        border: pw.TableBorder.all(color: _hairline, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.4,
        ),
        headerDecoration: pw.BoxDecoration(color: _navy),
        cellStyle: pw.TextStyle(fontSize: 8, color: _ink),
        cellHeight: 18,
        cellAlignments: {3: pw.Alignment.centerRight},
      ),
      // Running total, so the customer can reconcile the rows above at a glance.
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: _goldWash,
          border: pw.Border(
            left: pw.BorderSide(color: _hairline, width: 0.5),
            right: pw.BorderSide(color: _hairline, width: 0.5),
            bottom: pw.BorderSide(color: _hairline, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL PAID',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _goldDeep,
                letterSpacing: 0.6,
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Text(
              _money(inv.payments.fold<double>(0, (sum, p) => sum + p.amount)),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

/// Declaration / terms small print.
///
/// The verification code and QR were dropped from the printed bill on request.
/// `PrintableInvoice` still carries both, so in-app verification is unaffected.
pw.Widget _declaration(PrintableInvoice printable) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _hairline, width: 0.7),
      borderRadius: pw.BorderRadius.circular(5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DECLARATION',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _goldDeep,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'We declare that this invoice shows the actual price of the goods '
          'described and that all particulars are true and correct. Weights '
          'are as per BIS standards. Goods once sold will be exchanged as per '
          'store policy.',
          style: pw.TextStyle(
            fontSize: 7.5,
            color: _mutedInk,
            lineSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: ${_date(printable.generatedAt)}',
          style: pw.TextStyle(fontSize: 7.5, color: _mutedInk),
        ),
      ],
    ),
  );
}

/// Thank-you line above the signature blocks.
pw.Widget _thankYou() {
  return pw.Column(
    children: [
      pw.Text(
        'Thank you for your trust.',
        style: pw.TextStyle(fontSize: 9.5, color: _ink),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'We look forward to serving you again!',
        style: pw.TextStyle(fontSize: 9.5, color: _goldDeep),
      ),
    ],
  );
}

/// Shop contact strip and the brand band that close the bill.
pw.Widget _contactFooter(PrintableShop shop) {
  final bits = <String>[
    if (shop.phone != null) shop.phone!,
    if (shop.address != null) shop.address!,
    if (shop.email != null) shop.email!,
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      if (bits.isNotEmpty) ...[
        pw.Container(height: 0.7, color: _hairline),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            for (final bit in bits)
              pw.Flexible(
                child: pw.Text(
                  bit,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 8, color: _mutedInk),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 6),
      ],
      pw.Container(
        color: _navy,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Center(
          child: pw.Text(
            _brandStrip,
            style: pw.TextStyle(
              fontSize: 7.5,
              color: _gold,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Customer + authorised signatory blocks.
pw.Widget _signatures(PrintableShop shop) {
  pw.Widget block(String caption, {String? overline}) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (overline != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text(
            overline,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        )
      else
        pw.SizedBox(height: 28),
      pw.Container(width: 130, height: 0.7, color: _ink),
      pw.SizedBox(height: 3),
      pw.Text(caption, style: pw.TextStyle(fontSize: 8, color: _mutedInk)),
    ],
  );

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      block('Customer Signature'),
      block(
        'Authorised Signatory',
        overline: 'For ${shop.name ?? 'SwarnaLekh'}',
      ),
    ],
  );
}
