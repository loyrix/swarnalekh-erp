import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/inventory/application/inventory_import_parser.dart';

void main() {
  group('parseCsvSheet', () {
    test('splits headers from data rows and drops blank rows', () {
      const csv =
          'Tag,Item,Metal,Karat,Gross Wt,Net Wt\n'
          'RG-1,Gold Ring,Gold,22K,10.5,9.2\n'
          '\n'
          'PD-2,Pendant,Gold,18K,4,3.5\n';
      final sheet = parseCsvSheet(csv);
      expect(sheet.headers, [
        'Tag',
        'Item',
        'Metal',
        'Karat',
        'Gross Wt',
        'Net Wt',
      ]);
      expect(sheet.rows.length, 2);
      expect(sheet.rows[1][0], 'PD-2');
    });
  });

  group('autoDetectMapping', () {
    test('maps common header names to fields', () {
      final m = autoDetectMapping([
        'Tag Number',
        'Product',
        'Category',
        'Metal',
        'Purity',
        'Gross Weight',
        'Net Weight',
        'Qty',
        'Selling Price',
      ]);
      expect(m[ImportField.tagNumber], 0);
      expect(m[ImportField.itemName], 1);
      expect(m[ImportField.categoryName], 2);
      expect(m[ImportField.metalType], 3);
      expect(m[ImportField.karat], 4);
      expect(m[ImportField.grossWeight], 5);
      expect(m[ImportField.netWeight], 6);
      expect(m[ImportField.quantity], 7);
      expect(m[ImportField.sellingPrice], 8);
    });

    test('does not assign two fields to the same column', () {
      final m = autoDetectMapping(['Name', 'Weight']);
      final cols = m.values.toList();
      expect(cols.toSet().length, cols.length);
    });
  });

  group('buildImportRow', () {
    final mapping = {
      ImportField.tagNumber: 0,
      ImportField.itemName: 1,
      ImportField.metalType: 2,
      ImportField.karat: 3,
      ImportField.grossWeight: 4,
      ImportField.netWeight: 5,
      ImportField.categoryName: 6,
    };

    test('builds a valid payload and preserves the tag', () {
      final r = buildImportRow([
        'RG-0007',
        'Gold Ring',
        'Gold',
        '22K',
        '10.5',
        '9.25',
        'Ring',
      ], mapping);
      expect(r.isValid, isTrue);
      expect(r.payload!['tagNumber'], 'RG-0007');
      expect(r.payload!['metalType'], 'gold');
      expect(r.payload!['grossWeight'], 10.5);
      expect(r.payload!['categoryName'], 'Ring');
      expect(r.payload!['stockType'], 'unique');
    });

    test('flags missing name, bad metal, and net over gross', () {
      final r = buildImportRow([
        '',
        'X',
        'platinum',
        '',
        '5',
        '6',
        '',
      ], mapping);
      expect(r.isValid, isFalse);
      expect(r.errors, contains('Item name is required'));
      expect(r.errors, contains('Metal must be gold or silver'));
      expect(r.errors, contains('Net weight cannot exceed gross weight'));
    });

    test('tolerates currency symbols and thousands separators in numbers', () {
      final r = buildImportRow([
        'T1',
        'Chain',
        'gold',
        '22K',
        '1,234.50',
        '1,200.00',
        '',
      ], mapping);
      expect(r.isValid, isTrue);
      expect(r.payload!['grossWeight'], 1234.5);
    });
  });

  group('duplicateTagsInFile', () {
    test('finds case-insensitive duplicates and ignores blanks', () {
      final dupes = duplicateTagsInFile(['RG-1', 'rg-1', null, '', 'PD-2']);
      expect(dupes, {'rg-1'});
    });
  });
}
