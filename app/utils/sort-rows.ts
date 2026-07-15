import type { SortItem } from '@universal-ember/table/plugins/data-sorting';

/**
 * Compare two row objects according to the active multi-key sort spec.
 *
 * For each `SortItem`:
 *   - If both cells look like dates, compare chronologically.
 *   - Else if both cells parse as numbers, compare numerically.
 *   - Otherwise fall back to a locale-aware string compare.
 * The first non-zero comparison wins; descending direction inverts it.
 *
 * Dates must be checked before numbers: `parseFloat('2026-01-15')`
 * happily returns `2026`, which made every date within the same year
 * compare as equal (and `1/15/2026` compare as `1`).
 *
 * `SortDirection` is matched by its string value to keep this module
 * dependency-free of the table runtime — handy for unit tests and for
 * keeping this small primitive importable from anywhere.
 */
const DESCENDING = 'descending';

/**
 * Three date components with a 4-digit year leading (`2026-01-15`,
 * `2026/1/5`) or trailing (`1/15/2026`), optionally followed by a time.
 * `Date.parse` alone is far too permissive (`'1.5.3'` parses as
 * Jan 5 2003), so only strings matching this shape are handed to it.
 */
const DATE_LIKE =
  /^(?:\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4})(?:[T ].+)?$/;

function asTimestamp(value: string): number | undefined {
  if (!DATE_LIKE.test(value)) return undefined;
  const timestamp = Date.parse(value);
  return isNaN(timestamp) ? undefined : timestamp;
}

/**
 * Compare two cell values: chronologically when both look like dates,
 * numerically when both parse as numbers, locale-aware string compare
 * otherwise. Shared by row sorting and filter-option ordering.
 */
export function compareValues(a: string, b: string): number {
  const ad = asTimestamp(a);
  const bd = asTimestamp(b);

  if (ad !== undefined && bd !== undefined) {
    return ad - bd;
  }

  const af = parseFloat(a);
  const bf = parseFloat(b);

  if (!isNaN(af) && !isNaN(bf)) {
    return af - bf;
  }

  return a.localeCompare(b);
}

export function compareRows<T extends Record<string, string>>(
  sorts: ReadonlyArray<SortItem<T>>
): (a: T, b: T) => number {
  return (a, b) => {
    for (const { property, direction } of sorts) {
      const av = a[property as keyof T] ?? '';
      const bv = b[property as keyof T] ?? '';
      const result = compareValues(av, bv);

      if (result !== 0) {
        return String(direction) === DESCENDING ? -result : result;
      }
    }
    return 0;
  };
}

if (import.meta.vitest) {
  const { describe, it, expect } = import.meta.vitest;

  type Row = { name: string; score: string };
  type Direction = SortItem<Row>['direction'];
  const asc = (k: keyof Row): SortItem<Row> => ({
    property: k,
    direction: 'ascending' as Direction,
  });
  const desc = (k: keyof Row): SortItem<Row> => ({
    property: k,
    direction: 'descending' as Direction,
  });

  describe('compareValues', () => {
    it('orders numbers numerically, not lexically', () => {
      expect(['10', '2', '7'].sort(compareValues)).toEqual(['2', '7', '10']);
    });

    it('orders same-year dates chronologically', () => {
      expect(
        ['2026-11-30', '2026-01-15', '2026-03-02'].sort(compareValues)
      ).toEqual(['2026-01-15', '2026-03-02', '2026-11-30']);
    });

    it('orders plain strings with a locale-aware compare', () => {
      expect(['banana', 'apple', 'cherry'].sort(compareValues)).toEqual([
        'apple',
        'banana',
        'cherry',
      ]);
    });
  });

  describe('compareRows', () => {
    it('sorts numerically when both values parse as numbers', () => {
      const rows: Row[] = [
        { name: 'a', score: '10' },
        { name: 'b', score: '2' },
        { name: 'c', score: '7' },
      ];
      const sorted = [...rows].sort(compareRows([asc('score')]));
      expect(sorted.map((r) => r.score)).toEqual(['2', '7', '10']);
    });

    it('falls back to locale string compare for non-numeric cells', () => {
      const rows: Row[] = [
        { name: 'banana', score: 'x' },
        { name: 'apple', score: 'x' },
        { name: 'cherry', score: 'x' },
      ];
      const sorted = [...rows].sort(compareRows([asc('name')]));
      expect(sorted.map((r) => r.name)).toEqual(['apple', 'banana', 'cherry']);
    });

    it('inverts ordering for descending sorts', () => {
      const rows: Row[] = [
        { name: 'a', score: '1' },
        { name: 'b', score: '3' },
        { name: 'c', score: '2' },
      ];
      const sorted = [...rows].sort(compareRows([desc('score')]));
      expect(sorted.map((r) => r.score)).toEqual(['3', '2', '1']);
    });

    it('breaks ties using subsequent sort keys', () => {
      const rows: Row[] = [
        { name: 'b', score: '5' },
        { name: 'a', score: '5' },
        { name: 'c', score: '5' },
      ];
      const sorted = [...rows].sort(compareRows([asc('score'), asc('name')]));
      expect(sorted.map((r) => r.name)).toEqual(['a', 'b', 'c']);
    });

    it('handles missing values as empty strings', () => {
      const rows = [{ name: 'a' }, { name: 'b', score: '5' }] as Row[];
      const sorted = [...rows].sort(compareRows([asc('score')]));
      expect(sorted[0]?.name).toBe('a');
    });

    it('sorts numbers with unit suffixes numerically', () => {
      const rows: Row[] = [
        { name: 'a', score: '10.2s' },
        { name: 'b', score: '2.1s' },
        { name: 'c', score: '7s' },
      ];
      const sorted = [...rows].sort(compareRows([asc('score')]));
      expect(sorted.map((r) => r.score)).toEqual(['2.1s', '7s', '10.2s']);
    });
  });

  describe('compareRows: dates', () => {
    type DateRow = { edate: string };
    const byEdate = (direction: string): SortItem<DateRow>[] => [
      { property: 'edate', direction: direction as Direction },
    ];

    it('sorts ISO dates within the same year chronologically', () => {
      // Regression: parseFloat('2026-03-02') === 2026, so all same-year
      // dates used to compare as equal and never sorted.
      const rows: DateRow[] = [
        { edate: '2026-03-02' },
        { edate: '2026-11-30' },
        { edate: '2026-01-15' },
      ];
      const sorted = [...rows].sort(compareRows(byEdate('ascending')));
      expect(sorted.map((r) => r.edate)).toEqual([
        '2026-01-15',
        '2026-03-02',
        '2026-11-30',
      ]);
    });

    it('sorts ISO dates descending', () => {
      const rows: DateRow[] = [
        { edate: '2026-01-15' },
        { edate: '2026-11-30' },
        { edate: '2026-03-02' },
      ];
      const sorted = [...rows].sort(compareRows(byEdate('descending')));
      expect(sorted.map((r) => r.edate)).toEqual([
        '2026-11-30',
        '2026-03-02',
        '2026-01-15',
      ]);
    });

    it('sorts month-first slash dates chronologically, not by leading number', () => {
      // parseFloat('12/5/2024') === 12, which sorted these by month.
      const rows: DateRow[] = [
        { edate: '12/5/2024' },
        { edate: '1/15/2026' },
        { edate: '3/1/2024' },
      ];
      const sorted = [...rows].sort(compareRows(byEdate('ascending')));
      expect(sorted.map((r) => r.edate)).toEqual([
        '3/1/2024',
        '12/5/2024',
        '1/15/2026',
      ]);
    });

    it('sorts dates with time components', () => {
      const rows: DateRow[] = [
        { edate: '2026-01-15 10:30' },
        { edate: '2026-01-15 09:15' },
        { edate: '2026-01-14 23:59' },
      ];
      const sorted = [...rows].sort(compareRows(byEdate('ascending')));
      expect(sorted.map((r) => r.edate)).toEqual([
        '2026-01-14 23:59',
        '2026-01-15 09:15',
        '2026-01-15 10:30',
      ]);
    });

    it('sorts blank cells before dates, ascending', () => {
      const rows: DateRow[] = [
        { edate: '2026-01-15' },
        { edate: '' },
        { edate: '2026-01-02' },
      ];
      const sorted = [...rows].sort(compareRows(byEdate('ascending')));
      expect(sorted.map((r) => r.edate)).toEqual([
        '',
        '2026-01-02',
        '2026-01-15',
      ]);
    });

    it('does not treat version-like strings as dates', () => {
      // Date.parse('1.5.3') succeeds (!), so the date path must not
      // accept dot-separated values. Comparing as dates would put
      // '12.1.2' (Dec 1 2002) before '1.5.3' (Jan 5 2003).
      const rows: DateRow[] = [{ edate: '12.1.2' }, { edate: '1.5.3' }];
      const sorted = [...rows].sort(compareRows(byEdate('ascending')));
      expect(sorted.map((r) => r.edate)).toEqual(['1.5.3', '12.1.2']);
    });
  });
}
