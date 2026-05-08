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

import { convertMarkdown } from '#utils/markdown.ts';
import { rowHash } from '#utils/row-hash.ts';
import { compareRows } from '#utils/sort-rows.ts';
import { stickyOffset } from '#utils/sticky-offset.ts';
import { createUrlPreferencesAdapter } from '#utils/qp-preferences.ts';
import { isNumericColumn } from '#utils/numeric.ts';
import { Highlighting, colorFor } from '#utils/highlighting-plugin.ts';

const HASH_KEY = '__hash';

type Row = Record<string, string> & { [HASH_KEY]: string };

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
   * Source rows mapped onto the object shape the headless table expects.
   * Keys are the trimmed header names, so the column's `key` and
   * `name` are the same string. There's no synthetic index — sorting,
   * filtering, color highlighting all address columns by their human
   * name.
   *
   * `reactiveweb/map` keeps Row identity stable per source-row array,
   * so when the user toggles visibility/filter state we don't re-build
   * the headless table's Row<> wrappers.
   */
  allRows = map(this, {
    data: () => this.args.rows,
    map: (row: string[]): Row => {
      const obj = { [HASH_KEY]: rowHash(row) } as Row;
      const headers = this.headers;
      for (let i = 0; i < headers.length; i++) {
        obj[headers[i] as string] = row[i] ?? '';
      }
      return obj;
    },
  });

  @link filter = new Filter({
    data: () => this.allRows.values(),
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
      Highlighting.with(() => ({
        data: () => this.allRows.values(),
        colorRange: (column) => {
          const cv = this.qp.colorRangeFor(column.key);
          if (!cv) return undefined;
          return [cv[1], cv[2]] as const;
        },
      })),
    ],
  });

  @cached
  get columns() {
    return this.headers.map((name) => ({ name, key: name }));
  }

  /** Visible columns, supplied by the ColumnVisibility plugin. */
  get visibleColumns() {
    return tableColumns.for(this.table);
  }

  @cached
  get pinnedSet(): Set<string> {
    return new Set(this.qp.pinnedRows);
  }

  /**
   * Full Row[] handed to the headless table. We do _not_ slice by the
   * active filter — non-matching rows are hidden via CSS instead, which
   * keeps Row identities stable across filter state.
   */
  @cached
  get tableData(): Row[] {
    const sorts = this.sorts;
    const rows = this.allRows.values();
    if (sorts.length === 0) return rows;
    return [...rows].sort(compareRows(sorts));
  }

  /** Numeric-ness check used to decide whether to render the color toggle in Settings. */
  isNumeric = (key: string): boolean =>
    isNumericColumn(this.allRows.values(), key);

  // The "no results" row spans pin column + every visible column.
  get colspanWithPin() {
    return this.visibleColumns.length + 1;
  }

  hasEnoughToSort = () => this.tableData.length > 1;

  /**
   * Per-row visibility check used as a CSS class hint. Pinning
   * intentionally bypasses this — the pinned `<tbody>` always renders
   * pinned rows, even when they wouldn't pass the active filter.
   */
  rowMatchesFilter = (row: Row): boolean => this.filter.matchesRow(row);

  <template>
    <div class="toolbar">
      <button
        type="button"
        class="link-btn clear-filters"
        {{on "click" this.filter.clear}}
      >Clear filters</button>
      <Settings
        @table={{this.table}}
        @isNumeric={{this.isNumeric}}
      />
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
                            {{if (isAscending column) 'is-active'}}"
                          aria-label="Sort {{column.name}} ascending"
                          aria-pressed="{{isAscending column}}"
                          {{on "click" (fn sortAscending column)}}
                        >▲</button>
                        <button
                          type="button"
                          class="sort-btn
                            {{if (isDescending column) 'is-active'}}"
                          aria-label="Sort {{column.name}} descending"
                          aria-pressed="{{isDescending column}}"
                          {{on "click" (fn sortDescending column)}}
                        >▼</button>
                      </span>
                    {{/if}}
                  </div>
                  <Filters @column={{column.key}} @filter={{this.filter}} />
                </th>
              {{/each}}
            </tr>
          </thead>

          {{! Pinned rows live in their own sticky <tbody> so they all
              stack at the top of the scroll container. The body iteration
              below skips them. }}
          <tbody class="pinned-rows">
            {{#each this.table.rows as |row|}}
              {{#if (isSelected row)}}
                <tr class="is-pinned">
                  <td class="pin-col">
                    <button
                      type="button"
                      class="pin-btn is-pinned"
                      aria-label="Unpin row"
                      aria-pressed="true"
                      {{on "click" (fn toggleRowSelection row)}}
                    ><span aria-hidden="true">📌</span></button>
                  </td>
                  {{#each this.visibleColumns as |column|}}
                    {{! NOTE: not sanitized, because no user data is captured on this site.
                              Also, github sanitizes on save }}
                    <td
                      style="background: {{colorFor column (get row.data column.key)}}"
                    >{{{convertMarkdown (get row.data column.key)}}}</td>
                  {{/each}}
                </tr>
              {{/if}}
            {{/each}}
          </tbody>

          <tbody>
            {{#each this.table.rows as |row|}}
              {{#unless (isSelected row)}}
                <tr
                  class="{{unless
                      (this.rowMatchesFilter row.data)
                      'is-filtered-out'
                    }}"
                >
                  <td class="pin-col">
                    <button
                      type="button"
                      class="pin-btn"
                      aria-label="Pin row to top"
                      aria-pressed="false"
                      {{on "click" (fn toggleRowSelection row)}}
                    ><span aria-hidden="true">📌</span></button>
                  </td>
                  {{#each this.visibleColumns as |column|}}
                    {{! NOTE: not sanitized, because no user data is captured on this site.
                              Also, github sanitizes on save }}
                    <td
                      style="background: {{colorFor column (get row.data column.key)}}"
                    >{{{convertMarkdown (get row.data column.key)}}}</td>
                  {{/each}}
                </tr>
              {{/unless}}
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

// Local helpers for safe key-based access used in the template.
function get<T extends object, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
