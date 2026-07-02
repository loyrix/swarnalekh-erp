export type CsvValue = string | number | boolean | null | undefined;

/**
 * Serializes rows to RFC 4180 CSV — quotes any field containing a comma,
 * quote, or newline and doubles embedded quotes. Uses CRLF line endings.
 */
export function toCsv(headers: string[], rows: CsvValue[][]): string {
  const lines = [headers.map(escapeCsv).join(',')];
  for (const row of rows) {
    lines.push(row.map(escapeCsv).join(','));
  }
  return lines.join('\r\n');
}

function escapeCsv(value: CsvValue): string {
  if (value === null || value === undefined) return '';
  const text = String(value);
  if (/[",\n\r]/.test(text)) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

export interface CsvPayload {
  fileName: string;
  mimeType: 'text/csv';
  base64: string;
  byteLength: number;
  rowCount: number;
}

/**
 * Wraps CSV text into a downloadable payload. Prepends a UTF-8 BOM so Excel
 * opens non-ASCII (₹, Hindi/Gujarati) content correctly.
 */
export function csvPayload(
  fileNameBase: string,
  csv: string,
  rowCount: number,
): CsvPayload {
  const buffer = Buffer.from(`\uFEFF${csv}`, 'utf8');
  return {
    fileName: `${fileNameBase}.csv`,
    mimeType: 'text/csv',
    base64: buffer.toString('base64'),
    byteLength: buffer.byteLength,
    rowCount,
  };
}
