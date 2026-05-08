/**
 * Stable, content-based identifier for a row.
 *
 * Pinning is persisted via a query param, so we need an identifier that
 * survives page reloads and re-fetches of the same source data, but rows
 * arrive without natural primary keys. Hashing the joined cell text gives
 * us a key that's stable across loads of the same markdown table while
 * still gracefully drifting if the underlying data changes.
 */
export function rowHash(row: string[]): string {
  // FNV-1a 32-bit. Separator is NUL because it's vanishingly unlikely
  // to appear in cell text, so it doesn't collide on cell boundaries.
  const joined = row.join('\x00');
  let hash = 0x811c9dc5;
  for (let i = 0; i < joined.length; i++) {
    hash ^= joined.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return (hash >>> 0).toString(36);
}

if (import.meta.vitest) {
  const { describe, it, expect } = import.meta.vitest;

  describe('rowHash', () => {
    it('is stable for the same input', () => {
      const row = ['a', 'b', 'c'];
      expect(rowHash(row)).toBe(rowHash(row));
    });

    it('differs for different inputs', () => {
      expect(rowHash(['a'])).not.toBe(rowHash(['b']));
    });

    it("doesn't collide on naive join boundaries", () => {
      expect(rowHash(['a', 'b'])).not.toBe(rowHash(['ab']));
    });
  });
}
