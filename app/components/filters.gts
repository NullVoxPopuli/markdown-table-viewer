import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { cached, tracked } from '@glimmer/tracking';

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
  #isHiddenFn: (header: string) => boolean;

  constructor(options: {
    data: () => string[][];
    headers: () => string[];
    isHidden?: (header: string) => boolean;
  }) {
    this.#dataFn = options.data;
    this.#headerFn = options.headers;
    this.#isHiddenFn = options.isHidden ?? (() => false);
  }

  @cached
  private get incomingData() {
    return this.#dataFn();
  }

  get headers() {
    return this.#headerFn();
  }

  isHidden = (header: string) => this.#isHiddenFn(header);

  get visibleHeaders() {
    return this.headers.filter((h) => !this.#isHiddenFn(h));
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

        const headerName = filterName.endsWith('-search')
          ? filterName.replace(/-search$/, '')
          : filterName;

        // Hidden columns' filters are silently ignored.
        if (this.#isHiddenFn(headerName)) return true;

        if (filterName.endsWith('-search')) {
          if (Array.isArray(filters)) return true; // not allowed
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

export class Filters extends Component<{
  Args: {
    column: string;
    headers: string[];
    rows: string[][];
  };
}> {
  id = guidFor(this);

  get options() {
    const { column, headers, rows } = this.args;
    const index = headers.indexOf(column);

    const data = new Set(rows.map((row) => row[index]?.trim()).filter(Boolean));
    return data;
  }

  get hasOptions() {
    return this.options.size > 0;
  }

  <template>
    <div class="dynamic-filter">
      <input
        type="text"
        aria-label="Search {{@column}}"
        placeholder="Search…"
        name="{{@column}}-search"
        autocomplete="off"
      />
      {{#if this.hasOptions}}
        <select
          id={{this.id}}
          multiple
          aria-label="Filter {{@column}}"
          name={{@column}}
          size="3"
        >
          {{#each this.options as |opt|}}
            <option value={{opt}}>{{opt}}</option>
          {{/each}}
        </select>
      {{/if}}
    </div>
  </template>
}
