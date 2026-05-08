import type { SortItem } from '@universal-ember/table/plugins/data-sorting';

/**
 * Compare two row objects according to the active multi-key sort spec.
 *
 * For each `SortItem`:
 *   - If both cells parse as numbers, compare numerically.
 *   - Otherwise fall back to a locale-aware string compare.
 * The first non-zero comparison wins; descending direction inverts it.
 *
 * `SortDirection` is matched by its string value to keep this module
 * dependency-free of the table runtime — handy for unit tests and for
 * keeping this small primitive importable from anywhere.
 */
const DESCENDING = 'descending';

export function compareRows<T extends Record<string, string>>(
  sorts: ReadonlyArray<SortItem<T>>
): (a: T, b: T) => number {
  return (a, b) => {
    for (const { property, direction } of sorts) {
      const av = a[property as keyof T] ?? '';
      const bv = b[property as keyof T] ?? '';
      const af = parseFloat(av);
      const bf = parseFloat(bv);

      let result: number;
      if (!isNaN(af) && !isNaN(bf)) {
        result = af - bf;
      } else {
        result = av.localeCompare(bv);
      }

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
  });
}
