/**
 * Synthetic per-column keys used to back the headlessTable's data shape.
 *
 * Markdown headings can contain whitespace and characters that are awkward as
 * object keys, so we map each header index to `col0`, `col1`, … and convert
 * the array-of-arrays row data into key-addressed objects.
 */
const COL_KEY_PREFIX = 'col';

export function colKey(index: number): string {
  return `${COL_KEY_PREFIX}${index}`;
}

export function indexFromKey(key: string): number {
  return parseInt(key.slice(COL_KEY_PREFIX.length), 10);
}

if (import.meta.vitest) {
  const { describe, it, expect } = import.meta.vitest;

  describe('column-keys', () => {
    it('round-trips index → key → index', () => {
      for (const i of [0, 1, 7, 42]) {
        expect(indexFromKey(colKey(i))).toBe(i);
      }
    });
  });
}
