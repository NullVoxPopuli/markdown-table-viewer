import { Form } from 'ember-primitives/components/form';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { Filters } from './filters.gts';
import { Sorter, Sorts } from './sorter.gts';

interface FormFilters {
  [column: string]: string[];
}

export class DynamicTable extends Component<{
  headers: string[];
  rows: string[][];
}> {
  @tracked filters: undefined | FormFilters;

  sorter = new Sorter({
    data: () => this.filtered,
    headers: () => this.args.headers,
  });

  handleChange = (newValues: unknown) => {
    this.filters = newValues as FormFilters;
  };
  clear = () => (this.filters = {});

  get filtered() {
    const { rows, headers } = this.args;
    const filters = this.filters;

    if (!filters) {
      return rows;
    }

    return rows.filter((row) => {
      return Object.entries(filters).every(([filterName, filters]) => {
        if (filters.length === 0) return true;

        if (filterName.endsWith('-search')) {
          const headerName = filterName.replace(/-search$/, '');
          const hIndex = headers.indexOf(headerName);
          return row[hIndex]?.includes(filters);
        }

        const hIndex = headers.indexOf(filterName);
        return filters.some((filter) => row[hIndex]?.includes(filter));
      });
    });
  }

  <template>
    <section class="filters">
      <h2>Filters</h2>
      <Form @onChange={{this.handleChange}}>
        <div>
          {{#each @headers as |header|}}
            <Filters
              @column={{header}}
              @headers={{@headers}}
              @rows={{this.filtered}}
            />
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
                <Sorts @sorter={{this.sorter}} @column={{heading}} />
              </div>
            </th>
          {{/each}}
        </tr>
      </thead>
      <tbody>
        {{#each this.sorter.data as |row|}}
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
