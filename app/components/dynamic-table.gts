import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { Filter, Filters } from './filters.gts';
import { Form } from 'ember-primitives/components/form';
import { Settings } from './settings.gts';
import { link } from 'reactiveweb/link';
import { map } from 'reactiveweb/map';
import { interpolate, type Oklch } from 'culori';

import { headlessTable } from '@universal-ember/table';
import { columns as tableColumns } from '@universal-ember/table/plugins';
import {
  DataSorting,
  isAscending,
  isDescending,
  sortAscending,
  sortDescending,
} from '@universal-ember/table/plugins/data-sorting';
import { ColumnVisibility } from '@universal-ember/table/plugins/column-visibility';
import {
  RowSelection,
  isSelected,
  toggle as toggleRowSelection,
} from '@universal-ember/table/plugins/row-selection';

import type { SortItem } from '@universal-ember/table/plugins/data-sorting';
import type QPService from '#services/qp.ts';

import { colKey, indexFromKey } from '#utils/column-keys.ts';
import { isNumericColumn, numericRange } from '#utils/numeric.ts';
import { convertMarkdown } from '#utils/markdown.ts';
import { rowHash } from '#utils/row-hash.ts';
import { compareRows } from '#utils/sort-rows.ts';
import { stickyOffset } from '#utils/sticky-offset.ts';
import { createUrlPreferencesAdapter } from '#utils/qp-preferences.ts';

const HASH_KEY = '__hash';

type Row = Record<string, string> & { [HASH_KEY]: string };
type OklchInterpolator = (t: number) => Oklch;

export class DynamicTable extends Component<{
  Args: {
    headers: string[];
    rows: string[][];
  };
}> {
  @service declare qp: QPService;

  @cached
  get headers(): string[] {
    return this.args.headers.map((h) => h.trim());
  }

  /**
   * Source rows are reused for both the original `string[][]` filter
   * matching path and per-row hashing for pinning. Looking up a Row by
   * its source array is the cheapest way to keep identities stable
   * across renders.
   */
  @link filter = new Filter({
    data: () => this.args.rows,
    headers: () => this.headers,
  });

  @tracked sorts: SortItem<Row>[] = [];

  table = headlessTable<Row>(this, {
    columns: () => this.columns,
    data: () => this.tableData,
    /*
     * Plugins that speak the `preferences` API (currently
     * ColumnVisibility) round-trip their state through this URL-backed
     * adapter, so URL sharing happens for free without per-plugin
     * plumbing on our side.
     */
    preferences: () => ({
      key: 'table-viewer',
      adapter: createUrlPreferencesAdapter(this.qp.router),
    }),
    plugins: [
      DataSorting.with(() => ({
        sorts: this.sorts,
        onSort: (sorts) => (this.sorts = sorts as SortItem<Row>[]),
      })),
      ColumnVisibility,
      RowSelection.with(() => ({
        selection: this.pinnedSet,
        key: (data: Row) => data[HASH_KEY],
        onSelect: (key: string) => this.qp.togglePin(key),
        onDeselect: (key: string) => this.qp.togglePin(key),
      })),
    ],
  });

  @cached
  get columns() {
    return this.headers.map((name, index) => ({
      name,
      key: colKey(index),
    }));
  }

  /** Visible columns, supplied by the ColumnVisibility plugin. */
  get visibleColumns() {
    return tableColumns.for(this.table);
  }

  /**
   * Every input row, lazily wrapped into the object shape the headless
   * table expects. Each source-row array maps to a single, stable Row
   * instance — the headless table's own Row<> wrappers can reuse the
   * same reference instead of re-allocating on every render.
   */
  allRows = map(this, {
    data: () => this.args.rows,
    map: (row: string[]): Row => {
      const obj = { [HASH_KEY]: rowHash(row) } as Row;
      const headers = this.headers;
      for (let i = 0; i < headers.length; i++) {
        obj[colKey(i)] = row[i] ?? '';
      }
      return obj;
    },
  });

  @cached
  get pinnedSet(): Set<string> {
    return new Set(this.qp.pinnedRows);
  }

  /**
   * The full set of rows handed to the headless table. We do not slice
   * the array down by the active filter — non-matching rows are hidden
   * with `display: none` from the template instead, which keeps Row
   * identities (and the plugin's Row<> wrappers) stable as the user
   * filters and unfilters.
   */
  @cached
  get tableData(): Row[] {
    const sorts = this.sorts;
    const rows = this.allRows.values();
    if (sorts.length === 0) return rows;
    return [...rows].sort(compareRows(sorts));
  }

  @cached
  get numericColumnFlags(): boolean[] {
    return this.headers.map((_, i) => isNumericColumn(this.args.rows, i));
  }

  colorFor = (hIndex: number, value: string) => {
    if (!value) return;
    const heading = this.headers[hIndex];
    if (!heading) return;
    const num = parseFloat(value);

    if (isNaN(num)) return;

    const validation = this.qp.colorRangeFor(heading);
    if (!validation) return;

    const range = this.rangeOf(hIndex);
    if (!range || range.max === range.min) return;

    const interpolation = this.getInterpolation(
      hIndex,
      validation[1],
      validation[2]
    );
    const normalized = (num - range.min) / (range.max - range.min);
    const color = interpolation(normalized);

    return `oklch(${color.l} ${color.c} ${color.h}deg)`;
  };

  #rangeCache: Record<number, ReturnType<typeof numericRange>> = {};
  rangeOf = (hIndex: number) => {
    if (hIndex in this.#rangeCache) return this.#rangeCache[hIndex];
    const r = numericRange(this.args.rows, hIndex);
    this.#rangeCache[hIndex] = r;
    return r;
  };

  #interpolationCache: Record<string, OklchInterpolator> = {};
  getInterpolation(
    hIndex: number,
    end: string,
    start: string
  ): OklchInterpolator {
    const cacheKey = `${hIndex}|${end}|${start}`;
    const cached = this.#interpolationCache[cacheKey];
    if (cached) return cached;

    const interpolation = interpolate(
      [end, start],
      'oklch'
    ) as OklchInterpolator;
    this.#interpolationCache[cacheKey] = interpolation;
    return interpolation;
  }

  // The "no results" row spans pin column + every visible column.
  get colspanWithPin() {
    return this.visibleColumns.length + 1;
  }

  hasEnoughToSort = () => this.tableData.length > 1;
  cellIndex = (key: string) => indexFromKey(key);
  cellValue = (row: Row, key: string) => row[key] ?? '';
  headerForKey = (key: string) => this.headers[indexFromKey(key)] ?? '';

  /**
   * Per-row visibility check used as a CSS class hint. Pinning bypasses
   * the filter so a pinned row stays visible even if an aggressive
   * filter would otherwise hide it.
   */
  rowMatchesFilter = (row: Row): boolean => {
    const headers = this.headers;
    const source = headers.map((_, i) => row[colKey(i)] ?? '');
    return this.filter.matchesRow(source);
  };

  // Local references so they can be used as helpers in <template>.
  sortAsc = sortAscending;
  sortDesc = sortDescending;
  isAsc = isAscending;
  isDesc = isDescending;
  isPinned = isSelected;
  togglePin = toggleRowSelection;

  <template>
    <div class="toolbar">
      <button
        type="button"
        class="link-btn clear-filters"
        {{on "click" this.filter.clear}}
      >Clear filters</button>
      <Settings @table={{this.table}} @numericFlags={{this.numericColumnFlags}} />
    </div>

    <Form @onChange={{this.filter.handleChange}}>
      <div
        class="table-scroll"
        {{this.table.modifiers.container}}
        {{stickyOffset}}
      >
        <table>
          <thead>
            <tr>
              <th class="pin-col" aria-label="Pin row" />
              {{#each this.visibleColumns as |column|}}
                <th {{this.table.modifiers.columnHeader column}}>
                  <div class="heading">
                    <span class="name">{{column.name}}</span>
                    {{#if (this.hasEnoughToSort)}}
                      <span class="sort-controls">
                        <button
                          type="button"
                          class="sort-btn
                            {{if (this.isAsc column) 'is-active'}}"
                          aria-label="Sort {{column.name}} ascending"
                          aria-pressed="{{this.isAsc column}}"
                          {{on "click" (fn this.sortAsc column)}}
                        >▲</button>
                        <button
                          type="button"
                          class="sort-btn
                            {{if (this.isDesc column) 'is-active'}}"
                          aria-label="Sort {{column.name}} descending"
                          aria-pressed="{{this.isDesc column}}"
                          {{on "click" (fn this.sortDesc column)}}
                        >▼</button>
                      </span>
                    {{/if}}
                  </div>
                  <Filters
                    @column={{this.headerForKey column.key}}
                    @filter={{this.filter}}
                  />
                </th>
              {{/each}}
            </tr>
          </thead>
          <tbody>
            {{#each this.table.rows as |row|}}
              <tr
                class="{{if (this.isPinned row) 'is-pinned'}}
                  {{unless (this.rowMatchesFilter row.data) 'is-filtered-out'}}"
              >
                <td class="pin-col">
                  <button
                    type="button"
                    class="pin-btn {{if (this.isPinned row) 'is-pinned'}}"
                    aria-label={{if
                      (this.isPinned row)
                      "Unpin row"
                      "Pin row to top"
                    }}
                    aria-pressed="{{this.isPinned row}}"
                    {{on "click" (fn this.togglePin row)}}
                  >
                    <span aria-hidden="true">📌</span>
                  </button>
                </td>
                {{#each this.visibleColumns as |column|}}
                  {{! NOTE: not sanitized, because no user data is captured on this site.
                            Also, github sanitizes on save }}
                  <td
                    style="background: {{this.colorFor
                      (this.cellIndex column.key)
                      (this.cellValue row.data column.key)
                    }}"
                  >{{{convertMarkdown
                      (this.cellValue row.data column.key)
                    }}}</td>
                {{/each}}
              </tr>
            {{else}}
              <tr>
                <td colspan={{this.colspanWithPin}} class="no-results">No
                  results</td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    </Form>
  </template>
}
