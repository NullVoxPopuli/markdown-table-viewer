type Row = Record<string, string>;

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

  describe('numericRange', () => {
    it('returns min/max', () => {
      const rows = [{ x: '5' }, { x: '1' }, { x: '9' }, { x: 'not a number' }];
      expect(numericRange(rows, 'x')).toEqual({ min: 1, max: 9 });
    });

    it('returns undefined when no numbers', () => {
      const rows = [{ x: 'a' }, { x: 'b' }];
      expect(numericRange(rows, 'x')).toBeUndefined();
    });
  });
}
