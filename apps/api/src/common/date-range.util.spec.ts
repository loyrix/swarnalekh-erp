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

  it('resolves yesterday as the full prior day', () => {
    const range = resolveDateRange('yesterday', { now })!;
    expect(range.gte!.getDate()).toBe(14);
    expect(range.gte!.getHours()).toBe(0);
    expect(range.lte!.getDate()).toBe(14);
    expect(range.lte!.getHours()).toBe(23);
  });

  it('resolves last7 as an inclusive 7-day window ending today', () => {
    const range = resolveDateRange('last7', { now })!;
    expect(range.gte!.getDate()).toBe(9); // 15 - 6
    expect(range.lte!.getDate()).toBe(15);
  });

  it('resolves last30 as an inclusive 30-day window ending today', () => {
    const range = resolveDateRange('last30', { now })!;
    // 15 June - 29 days -> 17 May.
    expect(range.gte!.getMonth()).toBe(4);
    expect(range.gte!.getDate()).toBe(17);
  });

  it('resolves lastmonth as the whole previous calendar month', () => {
    const range = resolveDateRange('lastmonth', { now })!;
    expect(range.gte!.getMonth()).toBe(4); // May
    expect(range.gte!.getDate()).toBe(1);
    expect(range.lte!.getMonth()).toBe(4);
    expect(range.lte!.getDate()).toBe(31);
  });

  it('resolves the Indian financial year (1 April) start', () => {
    // June 2026 falls in FY 2026-27, which begins 1 April 2026.
    const range = resolveDateRange('financialyear', { now })!;
    expect(range.gte!.getFullYear()).toBe(2026);
    expect(range.gte!.getMonth()).toBe(3); // April
    expect(range.gte!.getDate()).toBe(1);

    // A January date belongs to the FY that began the previous April.
    const jan = resolveDateRange('financialyear', {
      now: new Date('2026-01-10T00:00:00.000Z'),
    })!;
    expect(jan.gte!.getFullYear()).toBe(2025);
    expect(jan.gte!.getMonth()).toBe(3);
  });
});
