import Component from '@glimmer/component';
import { Form } from 'ember-primitives/components/form';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { cached, tracked } from '@glimmer/tracking';
import type { TOC } from '@ember/component/template-only';

interface FormFilters {
  [column: string]: string | string[];
}

export class Filter {
  @tracked filters: undefined | FormFilters;
  clear = () => (this.filters = {});
  handleChange = (newValues: unknown) => {
    this.filters = newValues as FormFilters;
  };

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

  get headers() {
    return this.#headerFn();
  }

  @cached
  get data() {
    const rows = this.incomingData;
    const headers = this.headers;
    const filters = this.filters;

    if (!filters) {
      return rows;
    }

    return rows.filter((row) => {
      return Object.entries(filters).every(([filterName, filters]) => {
        if (filters.length === 0) return true;

        if (filterName.endsWith('-search')) {
          if (Array.isArray(filters)) return true; // not allowed
          const headerName = filterName.replace(/-search$/, '');
          const hIndex = headers.indexOf(headerName);
          return row[hIndex]?.includes(filters);
        }

        if (!Array.isArray(filters)) return true; // not allowed

        const hIndex = headers.indexOf(filterName);
        return filters.some((filter) => row[hIndex]?.includes(filter));
      });
    });
  }
}

export const FilterForm = <template>
  <section class="filters">
    <h2>Filters</h2>
    <Form @onChange={{@filters.handleChange}}>
      <div>
        {{#each @filters.headers as |header|}}
          <Filters
            @column={{header}}
            @headers={{@filters.headers}}
            @rows={{@filters.data}}
          />
        {{/each}}
      </div>
      <input
        aria-label="Clear the form"
        type="reset"
        value="Clear"
        {{on "click" @filters.clear}}
      />
    </Form>
  </section>
</template> satisfies TOC<{ filters: Filter }>;

export class Filters extends Component<{
  column: string;
  headers: string[];
  rows: string[][];
}> {
  id = guidFor(this);

  get options() {
    const { column, headers, rows } = this.args;
    const index = headers.indexOf(column);

    const data = new Set(rows.map((row) => row[index]?.trim()).filter(Boolean));
    return data;
  }
  <template>
    <span class="dynamic-filter">
      <span>
        <label for={{this.id}}>{{@column}}</label>

        <input aria-label="Search for {{@column}}" name="{{@column}}-search" />

      </span>
      <select id={{this.id}} multiple name={{@column}}>
        {{#each this.options as |opt|}}
          <option value={{opt}}>{{opt}}</option>
        {{/each}}
      </select>
    </span>
  </template>
}
