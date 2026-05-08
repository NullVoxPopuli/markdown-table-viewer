import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { on } from '@ember/modifier';
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

  hasFilterFor = (column: string): boolean => {
    const f = this.filters;
    if (!f) return false;
    const search = f[`${column}-search`];
    const multi = f[column];
    return (
      (typeof search === 'string' && search.length > 0) ||
      (Array.isArray(multi) && multi.length > 0)
    );
  };

  clearColumn = (column: string) => {
    const current = this.filters;
    if (!current) return;
    const next = { ...current };
    delete next[column];
    delete next[`${column}-search`];
    this.filters = next;
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

  /**
   * The full source data, exposed for callers that want to derive
   * dropdown options or do their own per-row matching with
   * {@link Filter.matchesRow}. Filtering itself is intentionally _not_
   * applied here — the consumer hides non-matching rows in the DOM
   * instead of rebuilding the row array on every filter change.
   */
  get data() {
    return this.incomingData;
  }

  /**
   * Does `row` (a source row from `data`) pass the active filters?
   *
   * Each form field is keyed either by column name (multi-select
   * picker) or `<column>-search` (free-text search). An empty value
   * means "no constraint on that column".
   */
  matchesRow(row: string[]): boolean {
    const filters = this.filters;
    if (!filters) return true;
    const headers = this.headers;

    for (const [filterName, value] of Object.entries(filters)) {
      if (value.length === 0) continue;

      if (filterName.endsWith('-search')) {
        if (Array.isArray(value)) continue; // not allowed
        const headerName = filterName.replace(/-search$/, '');
        const hIndex = headers.indexOf(headerName);
        if (!row[hIndex]?.includes(value)) return false;
        continue;
      }

      if (!Array.isArray(value)) continue; // not allowed
      const hIndex = headers.indexOf(filterName);
      if (!value.some((v) => row[hIndex]?.includes(v))) return false;
    }
    return true;
  }
}

export class Filters extends Component<{
  Args: {
    column: string;
    filter: Filter;
  };
}> {
  id = guidFor(this);

  get options() {
    const { column } = this.args;
    const headers = this.args.filter.headers;
    const rows = this.args.filter.data;
    const index = headers.indexOf(column);

    return new Set(rows.map((row) => row[index]?.trim()).filter(Boolean));
  }

  get hasOptions() {
    return this.options.size > 0;
  }

  get isActive() {
    return this.args.filter.hasFilterFor(this.args.column);
  }

  /**
   * Per-column clear: wipe the DOM controls for this filter, then dispatch
   * a bubbling `input` event so ember-primitives' Form re-reads the form
   * data and calls our `onChange` with the empty values.
   */
  handleClear = (event: MouseEvent) => {
    event.preventDefault();
    const button = event.currentTarget as HTMLElement;
    const wrapper = button.closest('.dynamic-filter');
    if (!wrapper) return;

    const search = wrapper.querySelector<HTMLInputElement>('input[type="text"]');
    if (search) search.value = '';

    const select = wrapper.querySelector<HTMLSelectElement>('select');
    if (select) {
      for (const opt of Array.from(select.options)) opt.selected = false;
    }

    wrapper.dispatchEvent(new Event('input', { bubbles: true }));
  };

  <template>
    <div class="dynamic-filter">
      <span class="filter-row">
        <input
          type="text"
          aria-label="Search {{@column}}"
          placeholder="Search…"
          name="{{@column}}-search"
          autocomplete="off"
        />
        {{#if this.isActive}}
          <button
            type="button"
            class="filter-clear"
            aria-label="Clear filter for {{@column}}"
            title="Clear {{@column}} filter"
            {{on "click" this.handleClear}}
          ><span aria-hidden="true">×</span></button>
        {{/if}}
      </span>
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
