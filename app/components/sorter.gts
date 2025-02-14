import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import type { TOC } from '@ember/component/template-only';

export class Sorter {
  @tracked sort: null | [string, 'asc' | 'desc'] = null;

  #dataFn: () => string[][];
  #headerFn: () => string[];

  constructor(options: { data: () => string[][]; headers: () => string[] }) {
    this.#dataFn = options.data;
    this.#headerFn = options.headers;
  }

  @cached
  private get incomingData() {
    return this.#dataFn();
  }

  get #headers() {
    return this.#headerFn();
  }

  sortAsc = (columnName: string) => {
    if (this.sort?.[0] === columnName) this.sort = null;

    this.sort = [columnName, 'asc'];
  };
  sortDesc = (columnName: string) => {
    if (this.sort?.[0] === columnName) this.sort = null;
    this.sort = [columnName, 'desc'];
  };

  isAscBy = (columnName: string) => {
    return this.sort?.[0] === columnName && this.sort?.[1] === 'asc';
  };

  isDescBy = (columnName: string) => {
    return this.sort?.[0] === columnName && this.sort?.[1] === 'desc';
  };

  @cached
  get data() {
    const sort = this.sort;
    const filtered = this.incomingData;

    if (!sort) return filtered;

    const [columnName, dir] = sort;
    const columnIndex = this.#headers.indexOf(columnName);

    if (columnIndex < 0) return filtered;

    return filtered.sort((a, b) => {
      const av = a[columnIndex];
      const bv = b[columnIndex];

      const af = parseFloat(av);
      const bf = parseFloat(bv);

      if (!isNaN(af) && !isNaN(bf)) {
        if (dir === 'asc') {
          return bf - af;
        }
        return af - bf;
      }

      if (dir === 'asc') {
        return (bv || '').localeCompare(av || '');
      }
      return (av || '').localeCompare(bv || '');
    });
  }

  get hasEnoughToSort() {
    return this.data.length > 1;
  }
}

export const Sorts = <template>
  {{#if @sorter.hasEnoughToSort}}
    {{#if (@sorter.isAscBy @column)}}
      <button disabled type="button"></button>
    {{else}}
      <button
        type="button"
        {{on "click" (fn @sorter.sortAsc @column)}}
      >▲</button>
    {{/if}}
    {{#if (@sorter.isDescBy @column)}}
      <button disabled type="button"></button>
    {{else}}
      <button
        type="button"
        {{on "click" (fn @sorter.sortDesc @column)}}
      >▼</button>
    {{/if}}
  {{/if}}
</template> satisfies TOC<{ sorter: Sorter; column: string }>;
