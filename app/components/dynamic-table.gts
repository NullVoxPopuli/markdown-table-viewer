import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { Filter, FilterForm } from './filters.gts';
import { link } from 'reactiveweb/link';
import { parseInline } from 'marked';
import { interpolate, type Oklch } from 'culori';

type OklchInterpolator = (t: number) => Oklch;

import { headlessTable } from '@universal-ember/table';
import {
  DataSorting,
  isAscending,
  isDescending,
  SortDirection,
  sortAscending,
  sortDescending,
} from '@universal-ember/table/plugins/data-sorting';

import type { SortItem } from '@universal-ember/table/plugins/data-sorting';
import type QPService from '#services/qp.ts';

type Row = Record<string, string>;

const COL_KEY_PREFIX = 'col';
const colKey = (index: number) => `${COL_KEY_PREFIX}${index}`;
const indexFromKey = (key: string) =>
  parseInt(key.slice(COL_KEY_PREFIX.length), 10);

function convertMarkdown(str: string): string {
  return parseInline(str ?? '', { gfm: true }) as string;
}

export class DynamicTable extends Component<{
  Args: {
    headers: string[];
    rows: string[][];
  };
}> {
  @service declare qp: QPService;

  @link filter = new Filter({
    data: () => this.args.rows,
    headers: () => this.args.headers,
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
    ],
  });

  @cached
  get columns() {
    return this.args.headers.map((name, index) => ({
      name,
      key: colKey(index),
    }));
  }

  @cached
  get rowsAsObjects(): Row[] {
    const headers = this.args.headers;
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

  colorFor = (hIndex: number, value: string) => {
    if (!value) return;
    const heading = this.args.headers[hIndex];
    if (!heading) return;
    const num = parseFloat(value);

    if (isNaN(num)) return;

    const validation = this.qp.conditionalValidations?.find(
      (v) => v[0] === heading
    );
    if (!validation) return;

    const interpolation = this.getInterpolation(
      hIndex,
      validation[1],
      validation[2]
    );

    const max = this.maxOf(hIndex);
    const min = this.minOf(hIndex);
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

  #interpolationCache: Record<number, OklchInterpolator> = {};
  getInterpolation(
    hIndex: number,
    end: string,
    start: string
  ): OklchInterpolator {
    const cached = this.#interpolationCache[hIndex];
    if (cached) return cached;

    const interpolation = interpolate([end, start], 'oklch') as OklchInterpolator;
    this.#interpolationCache[hIndex] = interpolation;
    return interpolation;
  }

  hasEnoughToSort = () => this.tableData.length > 1;
  cellIndex = (key: string) => indexFromKey(key);
  cellValue = (row: Row, key: string) => row[key] ?? '';

  // Local references so they can be used as helpers in <template>
  sortAsc = sortAscending;
  sortDesc = sortDescending;
  isAsc = isAscending;
  isDesc = isDescending;

  <template>
    <FilterForm @filters={{this.filter}} />

    <div class="table-scroll" {{this.table.modifiers.container}}>
      <table>
        <thead>
          <tr>
            {{#each this.table.columns as |column|}}
              <th {{this.table.modifiers.columnHeader column}}>
                <div class="heading">
                  <span class="name">{{column.name}}</span>
                  {{#if (this.hasEnoughToSort)}}
                    <span class="sort-controls">
                      <button
                        type="button"
                        class="sort-btn {{if (this.isAsc column) 'is-active'}}"
                        aria-label="Sort {{column.name}} ascending"
                        aria-pressed="{{this.isAsc column}}"
                        {{on "click" (fn this.sortAsc column)}}
                      >▲</button>
                      <button
                        type="button"
                        class="sort-btn {{if (this.isDesc column) 'is-active'}}"
                        aria-label="Sort {{column.name}} descending"
                        aria-pressed="{{this.isDesc column}}"
                        {{on "click" (fn this.sortDesc column)}}
                      >▼</button>
                    </span>
                  {{/if}}
                </div>
              </th>
            {{/each}}
          </tr>
        </thead>
        <tbody>
          {{#each this.table.rows as |row|}}
            <tr>
              {{#each this.table.columns as |column|}}
                {{! NOTE: not sanitized, because no user data is captured on this site.
                          Also, github sanitizes on save }}
                <td
                  style="background: {{this.colorFor
                    (this.cellIndex column.key)
                    (this.cellValue row.data column.key)
                  }}"
                >{{{convertMarkdown (this.cellValue row.data column.key)}}}</td>
              {{/each}}
            </tr>
          {{else}}
            <tr>
              <td colspan={{@headers.length}} class="no-results">No results</td>
            </tr>
          {{/each}}
        </tbody>
      </table>
    </div>
  </template>
}
