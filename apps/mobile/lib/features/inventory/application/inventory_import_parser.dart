import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

/// A target inventory field a spreadsheet column can be mapped to.
enum ImportField {
  tagNumber,
  itemName,
  categoryName,
  metalType,
  karat,
  grossWeight,
  netWeight,
  quantity,
  sellingPrice,
  huid,
}

extension ImportFieldInfo on ImportField {
  /// Whether a value is mandatory for the row to be importable.
  bool get required =>
      this == ImportField.itemName ||
      this == ImportField.metalType ||
      this == ImportField.grossWeight ||
      this == ImportField.netWeight;

  /// Header keywords that auto-map a spreadsheet column to this field.
  List<String> get aliases => switch (this) {
    ImportField.tagNumber => ['tag', 'tag number', 'tag no', 'tagno', 'code'],
    ImportField.itemName => ['item', 'name', 'product', 'description', 'desc'],
    ImportField.categoryName => ['category', 'type', 'ornament'],
    ImportField.metalType => ['metal', 'material'],
    ImportField.karat => ['karat', 'carat', 'purity', 'kt'],
    ImportField.grossWeight => ['gross', 'gross wt', 'gross weight', 'gwt'],
    ImportField.netWeight => ['net', 'net wt', 'net weight', 'nwt'],
    ImportField.quantity => ['qty', 'quantity', 'pcs', 'pieces'],
    ImportField.sellingPrice => [
      'price',
      'selling price',
      'mrp',
      'rate',
      'amount',
    ],
    ImportField.huid => ['huid', 'hallmark'],
  };
}

/// A parsed spreadsheet: a header row and the data rows below it.
class ParsedSheet {
  const ParsedSheet({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}

/// One built import row: the API payload (when valid) and any blocking errors.
class ImportRowResult {
  const ImportRowResult({required this.payload, required this.errors});

  final Map<String, dynamic>? payload;
  final List<String> errors;

  bool get isValid => errors.isEmpty && payload != null;
}

String _norm(String s) => s.trim().toLowerCase();

/// Parses CSV text into a [ParsedSheet]. Blank trailing rows are dropped.
ParsedSheet parseCsvSheet(String content) {
  final table = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
  return _toSheet(
    table.map((row) => row.map((c) => c?.toString() ?? '').toList()).toList(),
  );
}

/// Parses the first worksheet of an .xlsx file into a [ParsedSheet].
ParsedSheet parseXlsxSheet(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);

  final sharedStrings = <String>[];
  final ss = archive.findFile('xl/sharedStrings.xml');
  if (ss != null) {
    final doc = XmlDocument.parse(utf8.decode(ss.content as List<int>));
    for (final si in doc.findAllElements('si')) {
      sharedStrings.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }

  final sheets =
      archive.files
          .where(
            (f) =>
                f.name.startsWith('xl/worksheets/sheet') &&
                f.name.endsWith('.xml'),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  if (sheets.isEmpty) return const ParsedSheet(headers: [], rows: []);

  final doc = XmlDocument.parse(utf8.decode(sheets.first.content as List<int>));
  final rows = <List<String>>[];
  for (final row in doc.findAllElements('row')) {
    final cells = <int, String>{};
    var maxCol = -1;
    for (final c in row.findAllElements('c')) {
      final col = _columnIndex(c.getAttribute('r') ?? '');
      if (col < 0) continue;
      final type = c.getAttribute('t');
      String value;
      if (type == 's') {
        final idx = int.tryParse(c.getElement('v')?.innerText ?? '');
        value = (idx != null && idx >= 0 && idx < sharedStrings.length)
            ? sharedStrings[idx]
            : '';
      } else if (type == 'inlineStr') {
        value = c.findAllElements('t').map((t) => t.innerText).join();
      } else {
        value = c.getElement('v')?.innerText ?? '';
      }
      cells[col] = value;
      if (col > maxCol) maxCol = col;
    }
    rows.add(List<String>.generate(maxCol + 1, (i) => cells[i] ?? ''));
  }
  return _toSheet(rows);
}

/// Zero-based column index for a cell ref ("A1" → 0, "AB7" → 27). -1 if none.
int _columnIndex(String ref) {
  final letters = ref.replaceAll(RegExp(r'[0-9]'), '').toUpperCase();
  if (letters.isEmpty) return -1;
  var col = 0;
  for (final code in letters.codeUnits) {
    if (code < 65 || code > 90) return -1;
    col = col * 26 + (code - 64);
  }
  return col - 1;
}

ParsedSheet _toSheet(List<List<String>> table) {
  // Drop fully-empty rows (common trailing noise in exports).
  final rows = table.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
  if (rows.isEmpty) return const ParsedSheet(headers: [], rows: []);
  final headers = rows.first.map((c) => c.trim()).toList();
  return ParsedSheet(headers: headers, rows: rows.skip(1).toList());
}

/// Guesses a column for each field by matching header text against aliases.
/// Exact (normalised) matches win over substring matches.
Map<ImportField, int> autoDetectMapping(List<String> headers) {
  final mapping = <ImportField, int>{};
  final normHeaders = headers.map(_norm).toList();
  for (final field in ImportField.values) {
    final aliases = field.aliases;
    var chosen = -1;
    // Prefer an exact header match.
    for (var i = 0; i < normHeaders.length; i++) {
      if (aliases.contains(normHeaders[i])) {
        chosen = i;
        break;
      }
    }
    // Fall back to a substring match on the longest alias first.
    if (chosen < 0) {
      final ordered = [...aliases]
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final alias in ordered) {
        final i = normHeaders.indexWhere((h) => h.contains(alias));
        if (i >= 0 && !mapping.values.contains(i)) {
          chosen = i;
          break;
        }
      }
    }
    if (chosen >= 0 && !mapping.values.contains(chosen)) {
      mapping[field] = chosen;
    }
  }
  return mapping;
}

String? _cell(List<String> row, Map<ImportField, int> mapping, ImportField f) {
  final i = mapping[f];
  if (i == null || i < 0 || i >= row.length) return null;
  final v = row[i].trim();
  return v.isEmpty ? null : v;
}

double? _num(String? v) {
  if (v == null) return null;
  // Tolerate thousands separators and stray currency symbols.
  final cleaned = v.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Builds one import payload row from a data row and the chosen mapping,
/// collecting human-readable validation errors. Category name is passed
/// through for the caller to resolve to an id.
ImportRowResult buildImportRow(
  List<String> row,
  Map<ImportField, int> mapping,
) {
  final errors = <String>[];

  final itemName = _cell(row, mapping, ImportField.itemName);
  if (itemName == null || itemName.length < 2) {
    errors.add('Item name is required');
  }

  final metalRaw = _norm(_cell(row, mapping, ImportField.metalType) ?? '');
  final metal = metalRaw.contains('silver')
      ? 'silver'
      : metalRaw.contains('gold')
      ? 'gold'
      : '';
  if (metal.isEmpty) errors.add('Metal must be gold or silver');

  final gross = _num(_cell(row, mapping, ImportField.grossWeight));
  final net = _num(_cell(row, mapping, ImportField.netWeight));
  if (gross == null || gross <= 0) errors.add('Gross weight is required');
  if (net == null || net <= 0) errors.add('Net weight is required');
  if (gross != null && net != null && net > gross) {
    errors.add('Net weight cannot exceed gross weight');
  }

  final qtyRaw = _num(_cell(row, mapping, ImportField.quantity));
  final quantity = (qtyRaw == null || qtyRaw < 1) ? 1 : qtyRaw.round();
  final sellingPrice = _num(_cell(row, mapping, ImportField.sellingPrice));

  if (errors.isNotEmpty) {
    return ImportRowResult(payload: null, errors: errors);
  }

  return ImportRowResult(
    payload: {
      'itemName': itemName,
      'metalType': metal,
      'grossWeight': gross,
      'netWeight': net,
      'quantity': quantity,
      'stockType': quantity > 1 ? 'bulk' : 'unique',
      'status': 'in_stock',
      'source': 'import',
      if (_cell(row, mapping, ImportField.tagNumber) != null)
        'tagNumber': _cell(row, mapping, ImportField.tagNumber),
      if (_cell(row, mapping, ImportField.karat) != null)
        'karat': _cell(row, mapping, ImportField.karat),
      if (_cell(row, mapping, ImportField.huid) != null)
        'huid': _cell(row, mapping, ImportField.huid),
      if (_cell(row, mapping, ImportField.categoryName) != null)
        'categoryName': _cell(row, mapping, ImportField.categoryName),
      if (sellingPrice != null) 'sellingPrice': sellingPrice,
    },
    errors: const [],
  );
}

/// Tag numbers that appear on more than one row (case-insensitive). Duplicate
/// tags must be resolved before import — the server also rejects tags already
/// in stock.
Set<String> duplicateTagsInFile(Iterable<String?> tags) {
  final seen = <String>{};
  final dupes = <String>{};
  for (final tag in tags) {
    final t = tag?.trim().toLowerCase();
    if (t == null || t.isEmpty) continue;
    if (!seen.add(t)) dupes.add(t);
  }
  return dupes;
}
