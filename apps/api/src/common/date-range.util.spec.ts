import { resolveDateRange } from './date-range.util';

const now = new Date('2026-06-15T14:30:00.000Z');

describe('resolveDateRange', () => {
  it('defaults to today when the period is absent or unknown', () => {
    for (const period of [undefined, 'bogus']) {
      const range = resolveDateRange(period, { now })!;
      expect(range.gte!.getHours()).toBe(0);
      expect(range.gte!.getDate()).toBe(now.getDate());
      expect(range.lte!.getHours()).toBe(23);
    }
  });

  it('honours the provided default period', () => {
    const range = resolveDateRange(undefined, {
      now,
      defaultPeriod: 'month',
    })!;
    expect(range.gte!.getDate()).toBe(1);
  });

  it('returns null (no filter) for all-time', () => {
    expect(resolveDateRange('all', { now })).toBeNull();
  });

  it('rolls back N months for the month presets', () => {
    const six = resolveDateRange('6months', { now })!;
    expect(six.gte!.getMonth()).toBe(11); // June (5) - 6 -> December (11)
    expect(six.gte!.getFullYear()).toBe(2025);
  });

  it('builds a custom range from from/to (inclusive end of day)', () => {
    const range = resolveDateRange('custom', {
      now,
      dateFrom: '2026-01-01',
      dateTo: '2026-03-31',
    })!;
    expect(range.gte!.getFullYear()).toBe(2026);
    expect(range.lte!.getHours()).toBe(23);
  });

  it('treats an empty custom range as all-time', () => {
    expect(resolveDateRange('custom', { now })).toBeNull();
  });
});
