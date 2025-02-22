/**
 *
 * Can't use any of this yet, waiting on
 * - https://github.com/CrowdStrike/ember-headless-table/pull/281
 * - https://github.com/CrowdStrike/ember-headless-table/issues/284
 *
 * Tho, depending on expediance, I may have to fork it, we'll see!.
 *
 */
import Component from '@glimmer/component';
import { compare } from '@ember/utils';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { cached, tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';

import { headlessTable } from 'ember-headless-table';
import { meta, columns } from 'ember-headless-table/plugins';
import {
  ColumnResizing,
  isResizing,
  resizeHandle,
} from 'ember-headless-table/plugins/column-resizing';
import {
  ColumnReordering,
  moveLeft,
  moveRight,
  cannotMoveLeft,
  cannotMoveRight,
} from 'ember-headless-table/plugins/column-reordering';
import {
  ColumnVisibility,
  hide,
  show,
  isVisible,
  isHidden,
} from 'ember-headless-table/plugins/column-visibility';
import {
  DataSorting,
  sort,
  isAscending,
  isDescending,
} from 'ember-headless-table/plugins/data-sorting';

export default class Table extends Component<{
  headers: string[];
  rows: string[][];
}> {
  @cached
  get forTable() {
    const { headers, rows } = this.args;
    const result: Record<string, string>[] = [];

    for (const row of rows) {
      const entry = {};

      headers.forEach((name, i) => {
        entry[name] = row[i];
      });

      result.push(entry);
    }

    return result;
  }

  table = headlessTable(this, {
    data: () => this.forTable,
    plugins: [
      ColumnReordering,
      ColumnVisibility,
      ColumnResizing,
      DataSorting.with(() => ({
        sorts: this.sorts,
        onSort: (sorts) => (this.sorts = sorts),
      })),
    ],
  });

  @tracked sorts = [];

  get columns() {
    return columns.for(this.table);
  }

  get data() {
    return localSort(DATA, this.sorts);
  }

  get resizeHeight() {
    return htmlSafe(`${this.table.scrollContainerElement.clientHeight - 32}px`);
  }

  <template>
    <div class="flex gap-2">
      {{#each this.table.columns as |column|}}
        <span>
          {{column.name}}:
          <button {{on "click" (fn hide column)}} disabled={{isHidden column}}>
            Hide
          </button>
          <button {{on "click" (fn show column)}} disabled={{isVisible column}}>
            Show
          </button>
        </span>
      {{/each}}
    </div>
    <div class="h-full overflow-auto" {{this.table.modifiers.container}}>
      <table>
        <thead>
          <tr>
            {{#each this.columns as |column|}}
              <th
                {{this.table.modifiers.columnHeader column}}
                class="relative group"
              >
                <button
                  {{resizeHandle column}}
                  class="reset-styles absolute -left-4 cursor-col-resize focusable group-first:hidden"
                >
                  ↔
                </button>
                {{#if (isResizing column)}}
                  <div
                    class="absolute -left-3 -top-4 bg-focus w-0.5 transition duration-150"
                    style="height: {{this.resizeHeight}}"
                  ></div>
                {{/if}}

                <span class="name">{{column.name}}</span><br />
                <button
                  {{on "click" (fn moveLeft column)}}
                  disabled={{cannotMoveLeft column}}
                >
                  ⇦
                </button>
                <button
                  {{on "click" (fn moveRight column)}}
                  disabled={{cannotMoveRight column}}
                >
                  ⇨
                </button>
                <button {{on "click" (fn this.sort column)}}>
                  {{#if (isAscending column)}}
                    ×
                    <span class="sr-only">remove sort</span>
                  {{else if (isDescending column)}}
                    ⇧
                    <span class="sr-only">switch to ascending sort</span>
                  {{else}}
                    ⇩
                    <span class="sr-only">switch to ascending sort</span>
                  {{/if}}
                </button>
              </th>
            {{else}}
              <th>
                No columns are visible
              </th>
            {{/each}}
          </tr>
        </thead>
        <tbody>
          {{#each this.table.rows as |row|}}
            <tr>
              {{#each this.columns as |column|}}
                <td>
                  {{column.getValueForRow row}}</td>
              {{/each}}
            </tr>
          {{/each}}
        </tbody>
      </table>
    </div>
  </template>
}

/**
 * Utils, not the focus of the demo.
 * but sorting does need to be handled by you.
 */

function hasOwnProperty<T>(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function getValue<T>(obj, key) {
  if (hasOwnProperty(obj, key)) return obj[key];
}

export function localSort(data, sorts) {
  // you'll want to sort a duplicate of the array, because Array.prototype.sort mutates.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort
  //
  // Beware though that if the array is reactive,
  //   this will lose the reactivity if copying this function.
  return [...data].sort((itemA, itemB) => {
    for (const { direction, property } of sorts) {
      const valueA = getValue(itemA, property);
      const valueB = getValue(itemB, property);

      const result = compare(valueA, valueB);

      if (result) {
        return direction === 'descending' ? -result : result;
      }
    }

    return 0;
  });
}
