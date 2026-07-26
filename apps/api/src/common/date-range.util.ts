/**
 * Shared "stat period" resolver for dashboard figures (collections, sold, …).
 * Turns a period preset (or a custom from/to) into a Prisma date filter.
 */

export const STAT_PERIODS = [
  'today',
  'yesterday',
  'last7',
  'last30',
  'month',
  'lastmonth',
  '3months',
  '6months',
  '12months',
  'financialyear',
  'all',
  'custom',
] as const;

export type StatPeriod = (typeof STAT_PERIODS)[number];

/** A Prisma-compatible `{ gte, lte }` date filter (either bound optional). */
export interface DateRange {
  gte?: Date;
  lte?: Date;
}

function startOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function endOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x;
}

function monthsAgo(d: Date, months: number): Date {
  const x = startOfDay(d);
  x.setMonth(x.getMonth() - months);
  return x;
}

function daysAgo(d: Date, days: number): Date {
  const x = startOfDay(d);
  x.setDate(x.getDate() - days);
  return x;
}

/** Start of the Indian financial year (1 April) containing `d`. */
function financialYearStart(d: Date): Date {
  const year = d.getMonth() >= 3 ? d.getFullYear() : d.getFullYear() - 1;
  return startOfDay(new Date(year, 3, 1));
}

function parseBoundary(value: string | undefined, endOfDayBoundary: boolean) {
  if (!value?.trim()) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return endOfDayBoundary ? endOfDay(date) : startOfDay(date);
}

/**
 * Resolve a period into a date range. Returns `null` for "all time" (no filter).
 * Unknown/absent periods fall back to `defaultPeriod`.
 */
export function resolveDateRange(
  period: string | undefined,
  opts: {
    dateFrom?: string;
    dateTo?: string;
    defaultPeriod?: StatPeriod;
    now?: Date;
  } = {},
): DateRange | null {
  const now = opts.now ?? new Date();
  const requested = (period ?? '').trim().toLowerCase();
  const p = (STAT_PERIODS as readonly string[]).includes(requested)
    ? (requested as StatPeriod)
    : (opts.defaultPeriod ?? 'today');

  switch (p) {
    case 'all':
      return null;
    case 'custom': {
      const gte = parseBoundary(opts.dateFrom, false);
      const lte = parseBoundary(opts.dateTo, true);
      if (!gte && !lte) return null;
      return { ...(gte ? { gte } : {}), ...(lte ? { lte } : {}) };
    }
    case 'yesterday': {
      const start = daysAgo(now, 1);
      return { gte: start, lte: endOfDay(start) };
    }
    case 'last7':
      // Inclusive 7-day window ending today (today + 6 prior days).
      return { gte: daysAgo(now, 6), lte: endOfDay(now) };
    case 'last30':
      return { gte: daysAgo(now, 29), lte: endOfDay(now) };
    case 'month': {
      const start = startOfDay(now);
      start.setDate(1);
      return { gte: start, lte: endOfDay(now) };
    }
    case 'lastmonth': {
      const start = startOfDay(
        new Date(now.getFullYear(), now.getMonth() - 1, 1),
      );
      const end = endOfDay(new Date(now.getFullYear(), now.getMonth(), 0));
      return { gte: start, lte: end };
    }
    case '3months':
      return { gte: monthsAgo(now, 3), lte: endOfDay(now) };
    case '6months':
      return { gte: monthsAgo(now, 6), lte: endOfDay(now) };
    case '12months':
      return { gte: monthsAgo(now, 12), lte: endOfDay(now) };
    case 'financialyear':
      return { gte: financialYearStart(now), lte: endOfDay(now) };
    case 'today':
    default:
      return { gte: startOfDay(now), lte: endOfDay(now) };
  }
}
