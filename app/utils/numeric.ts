/**
 * Numeric helpers used by DynamicTable to decide which columns can be
 * sorted numerically and which can opt into color highlighting.
 */

/** How many non-empty rows we sample before deciding numeric-ness. */
const SAMPLE_SIZE = 25;

/** A column is "numeric" if at least this fraction of sampled rows parse as numbers. */
const THRESHOLD = 0.6;

/**
 * Heuristic: does the column at `hIndex` look numeric across the data set?
 *
 * We deliberately scan only the first `SAMPLE_SIZE` non-empty cells —
 * dynamic tables can be large and we only need a hint for UI affordances.
 */
export function isNumericColumn(rows: string[][], hIndex: number): boolean {
  let numeric = 0;
  let total = 0;

  for (const row of rows) {
    const v = row[hIndex];
    if (!v || !v.trim()) continue;
    total++;
    if (!isNaN(parseFloat(v))) numeric++;
    if (total >= SAMPLE_SIZE) break;
  }

  return total > 0 && numeric / total >= THRESHOLD;
}

/** Min/max of a column's parsable numeric values. Returns `undefined` when none. */
export function numericRange(
  rows: string[][],
  hIndex: number
): { min: number; max: number } | undefined {
  const values = rows
    .map((row) => parseFloat(row[hIndex] ?? ''))
    .filter((n) => !isNaN(n));

  if (values.length === 0) return undefined;

  return { min: Math.min(...values), max: Math.max(...values) };
}

if (import.meta.vitest) {
  const { describe, it, expect } = import.meta.vitest;

  describe('isNumericColumn', () => {
    it('returns true when most cells are numbers', () => {
      const rows = [
        ['a', '1'],
        ['b', '2'],
        ['c', '3.5'],
        ['d', 'xx'],
      ];
      expect(isNumericColumn(rows, 1)).toBe(true);
    });

    it('returns false when most cells are not numbers', () => {
      const rows = [
        ['1', 'a'],
        ['2', 'b'],
        ['3', 'c'],
      ];
      expect(isNumericColumn(rows, 1)).toBe(false);
    });

    it('ignores empty cells', () => {
      const rows = [
        ['', ''],
        ['', '1.0'],
        ['', '2.0'],
      ];
      expect(isNumericColumn(rows, 1)).toBe(true);
    });
  });

  describe('numericRange', () => {
    it('returns min/max', () => {
      const rows = [
        ['a', '5'],
        ['b', '1'],
        ['c', '9'],
        ['d', 'x'],
      ];
      expect(numericRange(rows, 1)).toEqual({ min: 1, max: 9 });
    });

    it('returns undefined when no numbers', () => {
      const rows = [
        ['a', 'x'],
        ['b', 'y'],
      ];
      expect(numericRange(rows, 1)).toBeUndefined();
    });
  });
}
