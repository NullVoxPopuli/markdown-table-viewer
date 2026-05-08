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
  SortDirection,
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

  @link filter = new Filter({
    data: () => this.args.rows,
    headers: () => this.headers,
    isHidden: (header) => this.qp.isHidden(header),
  });

  @tracked sorts: SortItem<Row>[] = [];

  table = headlessTable<Row>(this, {
    columns: () => this.columns,
    data: () => this.tableData,
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
    const hidden = new Set(this.qp.hiddenColumns);
    return this.headers.map((name, index) => ({
      name,
      key: colKey(index),
      pluginOptions: [
        ColumnVisibility.forColumn(() => ({
          isVisible: !hidden.has(name),
        })),
      ],
    }));
  }

  /** Visible columns, as filtered by the ColumnVisibility plugin. */
  @cached
  get visibleColumns() {
    return tableColumns.for(this.table);
  }

  /**
   * Every input row, lazily wrapped into the object shape the headless table
   * expects. Each source-row array maps to a single, stable Row instance —
   * downstream filtering, pinning, and the headless table's own Row<>
   * wrappers can all reuse the same reference instead of re-allocating on
   * every render.
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

  /** source-row → index lookup so filter results can map back to allRows. */
  @cached
  get sourceIndex(): Map<string[], number> {
    const out = new Map<string[], number>();
    const arr = this.args.rows;
    for (let i = 0; i < arr.length; i++) {
      out.set(arr[i] as string[], i);
    }
    return out;
  }

  @cached
  get pinnedSet(): Set<string> {
    return new Set(this.qp.pinnedRows);
  }

  @cached
  get pinnedRows(): Row[] {
    const set = this.pinnedSet;
    if (set.size === 0) return [];
    return this.allRows.values().filter((r) => set.has(r[HASH_KEY]));
  }

  /**
   * Filter applies to the un-pinned rows; pinned ones bypass it entirely.
   * Resolves each filtered source row to its cached Row from `allRows` so
   * downstream consumers see the same identity across renders.
   */
  @cached
  get unpinnedFiltered(): Row[] {
    const set = this.pinnedSet;
    const idx = this.sourceIndex;
    const result: Row[] = [];
    for (const src of this.filter.data) {
      const i = idx.get(src);
      if (i === undefined) continue;
      const row = this.allRows[i];
      if (!row || set.has(row[HASH_KEY])) continue;
      result.push(row);
    }
    return result;
  }

  @cached
  get tableData(): Row[] {
    const sorts = this.sorts;
    const unpinned = this.unpinnedFiltered;

    const sorted =
      sorts.length === 0
        ? unpinned
        : [...unpinned].sort((a, b) => {
            for (const { property, direction } of sorts) {
              const av = a[property] ?? '';
              const bv = b[property] ?? '';
              const af = parseFloat(av);
              const bf = parseFloat(bv);

              let result: number;
              if (!isNaN(af) && !isNaN(bf)) {
                result = af - bf;
              } else {
                result = av.localeCompare(bv);
              }

              if (result !== 0) {
                return direction === SortDirection.Descending
                  ? -result
                  : result;
              }
            }
            return 0;
          });

    return [...this.pinnedRows, ...sorted];
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

  hasEnoughToSort = () => this.tableData.length > 1;
  get colspanWithPin() {
    return this.visibleColumns.length + 1;
  }
  cellIndex = (key: string) => indexFromKey(key);
  cellValue = (row: Row, key: string) => row[key] ?? '';
  headerForKey = (key: string) => this.headers[indexFromKey(key)] ?? '';

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
      <Settings
        @columns={{this.columns}}
        @numericFlags={{this.numericColumnFlags}}
      />
    </div>

    <Form @onChange={{this.filter.handleChange}}>
      <div class="table-scroll" {{this.table.modifiers.container}}>
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
              <tr class="{{if (this.isPinned row) 'is-pinned'}}">
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
