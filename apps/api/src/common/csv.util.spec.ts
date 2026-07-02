import { csvPayload, toCsv } from './csv.util';

describe('toCsv', () => {
  it('joins headers and rows with CRLF', () => {
    const csv = toCsv(
      ['A', 'B'],
      [
        ['1', '2'],
        ['3', '4'],
      ],
    );
    expect(csv).toBe('A,B\r\n1,2\r\n3,4');
  });

  it('quotes fields with commas, quotes, or newlines and doubles quotes', () => {
    const csv = toCsv(['Name', 'Note'], [['Doe, John', 'He said "hi"\nbye']]);
    expect(csv).toBe('Name,Note\r\n"Doe, John","He said ""hi""\nbye"');
  });

  it('renders null/undefined as empty and keeps numbers', () => {
    const csv = toCsv(['X', 'Y', 'Z'], [[null, undefined, 42]]);
    expect(csv).toBe('X,Y,Z\r\n,,42');
  });
});

describe('csvPayload', () => {
  it('wraps CSV with a UTF-8 BOM and reports metadata', () => {
    const payload = csvPayload('invoices-2026-06-10', 'A,B\r\n1,2', 1);
    expect(payload.fileName).toBe('invoices-2026-06-10.csv');
    expect(payload.mimeType).toBe('text/csv');
    expect(payload.rowCount).toBe(1);

    const decoded = Buffer.from(payload.base64, 'base64').toString('utf8');
    expect(decoded.charCodeAt(0)).toBe(0xfeff); // BOM
    expect(decoded.slice(1)).toBe('A,B\r\n1,2');
  });
});
