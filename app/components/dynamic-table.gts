import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { Filter, Filters } from './filters.gts';
import { Form } from 'ember-primitives/components/form';
import { Settings } from './settings.gts';
import { link } from 'reactiveweb/link';
import { parseInline } from 'marked';
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
import {
  ColumnVisibility,
  isHidden,
} from '@universal-ember/table/plugins/column-visibility';

import type { SortItem } from '@universal-ember/table/plugins/data-sorting';
import type QPService from '#services/qp.ts';

type Row = Record<string, string>;
type OklchInterpolator = (t: number) => Oklch;

const COL_KEY_PREFIX = 'col';
const colKey = (index: number) => `${COL_KEY_PREFIX}${index}`;
const indexFromKey = (key: string) =>
  parseInt(key.slice(COL_KEY_PREFIX.length), 10);

function convertMarkdown(str: string): string {
  return parseInline(str ?? '', { gfm: true }) as string;
}

function isNumericColumn(rows: string[][], hIndex: number): boolean {
  let numeric = 0;
  let total = 0;
  for (const row of rows) {
    const v = row[hIndex];
    if (!v || !v.trim()) continue;
    total++;
    if (!isNaN(parseFloat(v))) numeric++;
    if (total >= 25) break;
  }
  return total > 0 && numeric / total >= 0.6;
}

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

  @cached
  get visibleColumns() {
    return tableColumns.for(this.table).filter((c) => !isHidden(c));
  }

  @cached
  get rowsAsObjects(): Row[] {
    const headers = this.headers;
    return this.filter.data.map((row) => {
      const obj: Row = {};
      for (let i = 0; i < headers.length; i++) {
        obj[colKey(i)] = row[i] ?? '';
      }
      return obj;
    });
  }

  @cached
  get tableData(): Row[] {
    const sorts = this.sorts;
    const data = this.rowsAsObjects;

    if (sorts.length === 0) return data;

    return [...data].sort((a, b) => {
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
          return direction === SortDirection.Descending ? -result : result;
        }
      }
      return 0;
    });
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

    const interpolation = this.getInterpolation(
      hIndex,
      validation[1],
      validation[2]
    );

    const max = this.maxOf(hIndex);
    const min = this.minOf(hIndex);
    if (max === min) return;
    const normalized = (num - min) / (max - min);
    const color = interpolation(normalized);

    return `oklch(${color.l} ${color.c} ${color.h}deg)`;
  };

  #maxCache: Record<number, number> = {};
  #minCache: Record<number, number> = {};
  maxOf = (hIndex: number) => {
    if (this.#maxCache[hIndex] !== undefined) return this.#maxCache[hIndex];
    const values = this.args.rows
      .map((row) => parseFloat(row[hIndex] ?? ''))
      .filter((n) => !isNaN(n));
    const max = Math.max(...values);
    this.#maxCache[hIndex] = max;
    return max;
  };
  minOf = (hIndex: number) => {
    if (this.#minCache[hIndex] !== undefined) return this.#minCache[hIndex];
    const values = this.args.rows
      .map((row) => parseFloat(row[hIndex] ?? ''))
      .filter((n) => !isNaN(n));
    const min = Math.min(...values);
    this.#minCache[hIndex] = min;
    return min;
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
  cellIndex = (key: string) => indexFromKey(key);
  cellValue = (row: Row, key: string) => row[key] ?? '';
  isNumericKey = (key: string) =>
    this.numericColumnFlags[indexFromKey(key)] ?? false;
  headerForKey = (key: string) => this.headers[indexFromKey(key)] ?? '';

  // Local references so they can be used as helpers in <template>
  sortAsc = sortAscending;
  sortDesc = sortDescending;
  isAsc = isAscending;
  isDesc = isDescending;

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
                    @headers={{this.filter.headers}}
                    @rows={{this.filter.data}}
                  />
                </th>
              {{/each}}
            </tr>
          </thead>
          <tbody>
            {{#each this.table.rows as |row|}}
              <tr>
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
                <td colspan={{this.visibleColumns.length}} class="no-results">No
                  results</td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    </Form>
  </template>
}
