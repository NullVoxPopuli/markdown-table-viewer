import { cached } from '@glimmer/tracking';
import { interpolate, type Oklch } from 'culori';

import { BasePlugin, meta, options } from '@universal-ember/table/plugins';
import type { Column } from '@universal-ember/table';
import type { PluginSignature } from '@universal-ember/table/plugins';

import { numericRange } from './numeric.ts';

type OklchInterpolator = (t: number) => Oklch;

/**
 * @universal-ember/table plugin that owns the per-column color
 * highlighting:
 *
 *   - Caches each column's `[min, max]` over the full data set once.
 *   - Caches the oklch interpolator until the user changes the color
 *     range.
 *   - Exposes `colorFor(value)` on the column meta so cell rendering
 *     in the host component is just `colorFor(column, value)`.
 *
 * The plugin doesn't own any storage — it reads everything it needs
 * from `Highlighting.with()` options the host supplies. That keeps the
 * highlighting state in whatever the host already uses (a query param,
 * a pref, etc.) and keeps this plugin generic.
 */

export interface Signature<
  T extends Record<string, string> = Record<string, string>,
> extends PluginSignature {
  Meta: { Column: ColumnMeta<T> };
  Options: {
    Plugin: {
      /**
       * The full row set, used to compute each column's numeric range
       * once. Should return _all_ rows, not the filtered view.
       */
      data: () => T[];
      /**
       * `[lowColor, highColor]` for `column`, or `undefined` to
       * disable highlighting for that column.
       */
      colorRange: (column: Column<T>) => readonly [string, string] | undefined;
    };
  };
}

class ColumnMeta<T extends Record<string, string> = Record<string, string>> {
  constructor(private column: Column<T>) {}

  #options(): Signature<T>['Options']['Plugin'] {
    return options.forTable(
      this.column.table,
      Highlighting
    ) as unknown as Signature<T>['Options']['Plugin'];
  }

  /** Computed once per column; invalidates only when the data set itself changes. */
  @cached
  get range(): { min: number; max: number } | undefined {
    return numericRange(this.#options().data(), this.column.key);
  }

  /** Built once per `colorRange()` change; reused for every cell. */
  @cached
  get interpolator(): OklchInterpolator | undefined {
    const range = this.#options().colorRange(this.column);
    if (!range) return undefined;
    const [low, high] = range;
    return interpolate([low, high], 'oklch');
  }

  /** CSS `oklch(...)` for `value`, or `undefined` if not applicable. */
  colorFor(value: string): string | undefined {
    if (!value) return undefined;
    const num = parseFloat(value);
    if (isNaN(num)) return undefined;
    const range = this.range;
    if (!range || range.max === range.min) return undefined;
    const interp = this.interpolator;
    if (!interp) return undefined;
    const normalized = (num - range.min) / (range.max - range.min);
    const c = interp(normalized);
    return `oklch(${c.l} ${c.c} ${c.h}deg)`;
  }
}

export class Highlighting<
  T extends Record<string, string> = Record<string, string>,
> extends BasePlugin<Signature<T>> {
  name = 'highlighting';
  meta = { column: ColumnMeta };
}

/** Convenience helper: `colorFor(column, value)` from a template. */
export function colorFor<T extends Record<string, string>>(
  column: Column<T>,
  value: string
): string | undefined {
  return meta.forColumn(column, Highlighting).colorFor(value);
}

/** Whether `column` actually has any numeric data — used to gate UI. */
export function hasNumericRange<T extends Record<string, string>>(
  column: Column<T>
): boolean {
  return meta.forColumn(column, Highlighting).range !== undefined;
}
