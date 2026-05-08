/**
 * Numeric helpers used by DynamicTable. The same column may be both
 * sorted numerically and color-highlighted; these helpers just provide
 * the underlying detection and range computation.
 */

type Row = Record<string, string>;

/** How many non-empty rows we sample before deciding numeric-ness. */
const SAMPLE_SIZE = 25;

/** A column is "numeric" if at least this fraction of sampled rows parse as numbers. */
const THRESHOLD = 0.6;

/**
 * Heuristic: does the column at `key` look numeric across the data set?
 *
 * We deliberately scan only the first `SAMPLE_SIZE` non-empty cells —
 * dynamic tables can be large and we only need a hint for UI affordances.
 */
export function isNumericColumn(rows: Row[], key: string): boolean {
  let numeric = 0;
  let total = 0;

  for (const row of rows) {
    const v = row[key];
    if (!v || !v.trim()) continue;
    total++;
    if (!isNaN(parseFloat(v))) numeric++;
    if (total >= SAMPLE_SIZE) break;
  }

  return total > 0 && numeric / total >= THRESHOLD;
}

/** Min/max of a column's parsable numeric values. Returns `undefined` when none. */
export function numericRange(
  rows: Row[],
  key: string
): { min: number; max: number } | undefined {
  let min = Infinity;
  let max = -Infinity;
  let any = false;

  for (const row of rows) {
    const num = parseFloat(row[key] ?? '');
    if (isNaN(num)) continue;
    any = true;
    if (num < min) min = num;
    if (num > max) max = num;
  }

  if (!any) return undefined;
  return { min, max };
}

if (import.meta.vitest) {
  const { describe, it, expect } = import.meta.vitest;

  describe('isNumericColumn', () => {
    it('returns true when most cells are numbers', () => {
      const rows = [
        { name: 'a', score: '1' },
        { name: 'b', score: '2' },
        { name: 'c', score: '3.5' },
        { name: 'd', score: 'xx' },
      ];
      expect(isNumericColumn(rows, 'score')).toBe(true);
    });

    it('returns false when most cells are not numbers', () => {
      const rows = [
        { name: '1', val: 'a' },
        { name: '2', val: 'b' },
        { name: '3', val: 'c' },
      ];
      expect(isNumericColumn(rows, 'val')).toBe(false);
    });

    it('ignores empty cells', () => {
      const rows = [
        { name: '', val: '' },
        { name: '', val: '1.0' },
        { name: '', val: '2.0' },
      ];
      expect(isNumericColumn(rows, 'val')).toBe(true);
    });
  });

  describe('numericRange', () => {
    it('returns min/max', () => {
      const rows = [
        { x: '5' },
        { x: '1' },
        { x: '9' },
        { x: 'not a number' },
      ];
      expect(numericRange(rows, 'x')).toEqual({ min: 1, max: 9 });
    });

    it('returns undefined when no numbers', () => {
      const rows = [{ x: 'a' }, { x: 'b' }];
      expect(numericRange(rows, 'x')).toBeUndefined();
    });
  });
}
