import { Form } from 'ember-primitives/components/form';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { Filters } from './filters.gts';

interface FormFilters {
  [column: string]: string[];
}

export class DynamicTable extends Component<{
  headers: string[];
  rows: string[][];
}> {
  @tracked filters: undefined | FormFilters;
  @tracked sort: null | [string, 'asc' | 'desc'] = null;

  handleChange = (newValues: unknown) => {
    this.filters = newValues as FormFilters;
  };
  clear = () => (this.filters = {});
  sortAsc = (columnName: string) => {
    if (this.sort?.[0] === columnName) this.sort = null;
    this.sort = [columnName, 'asc'];
  };
  sortDesc = (columnName: string) => {
    if (this.sort?.[0] === columnName) this.sort = null;
    this.sort = [columnName, 'desc'];
  };

  isAscBy = (columnName: string) =>
    this.sort?.[0] === columnName && this.sort?.[1] === 'asc';

  isDescBy = (columnName: string) =>
    this.sort?.[0] === columnName && this.sort?.[1] === 'desc';

  get filtered() {
    const { rows, headers } = this.args;
    const filters = this.filters;

    if (!filters) {
      return rows;
    }

    return rows.filter((row) => {
      return Object.entries(filters).every(([header, filters]) => {
        if (filters.length === 0) return true;

        const hIndex = headers.indexOf(header);
        return filters.some((filter) => row[hIndex]?.includes(filter));
      });
    });
  }

  @cached
  get sorted() {
    const { filtered, sort } = this;

    if (!sort) return filtered;

    const [columnName, dir] = sort;
    const columnIndex = this.args.headers.indexOf(columnName);

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
    return this.sorted.length > 1;
  }

  <template>
    <section class="filters">
      <h2>Filters</h2>
      <Form @onChange={{this.handleChange}}>
        <div>
          {{#each @headers as |header|}}
            <Filters @column={{header}} @headers={{@headers}} @rows={{@rows}} />
          {{/each}}
        </div>
        <input
          aria-label="Clear the form"
          type="reset"
          value="Clear"
          {{on "click" this.clear}}
        />
      </Form>
    </section>

    <table>
      <thead>
        <tr>
          {{#each @headers as |heading|}}
            <th>
              <div class="heading">
                <span>{{heading}}</span>
                {{#if this.hasEnoughToSort}}
                  {{#if (this.isAscBy heading)}}
                    <button disabled type="button"></button>
                  {{else}}
                    <button
                      type="button"
                      {{on "click" (fn this.sortAsc heading)}}
                    >▲</button>
                  {{/if}}
                  {{#if (this.isDescBy heading)}}
                    <button disabled type="button"></button>
                  {{else}}
                    <button
                      type="button"
                      {{on "click" (fn this.sortDesc heading)}}
                    >▼</button>
                  {{/if}}
                {{/if}}
              </div>
            </th>
          {{/each}}
        </tr>
      </thead>
      <tbody>
        {{#each this.sorted as |row|}}
          <tr>
            {{#each row as |datum|}}
              <td>{{datum}}</td>
            {{/each}}
          </tr>
        {{else}}
          <tr>
            <td colspan={{@headers.length}}>No results</td>
          </tr>
        {{/each}}
      </tbody>
    </table>
  </template>
}
