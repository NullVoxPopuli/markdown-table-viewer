import { Form } from 'ember-primitives/components/form';
import { Header } from '#components/header.gts';
import type { TOC } from '@ember/component/template-only';
import { pageTitle } from 'ember-page-title';
import type { Model } from '#routes/application.ts';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

function filter(data: string[][], headers: string[], filters: object) {
  return data;
}

class Filters extends Component<{
  column: string;
  headers: string[];
  rows: string[][];
}> {
  get options() {
    const { column, headers, rows } = this.args;
    const index = headers.indexOf(column);

    const data = new Set(rows.map((row) => row[index]?.trim()).filter(Boolean));
    return data;
  }
  <template>
    <label class="dynamic-filter">
      <span>{{@column}}</span>
      <select multiple name={{@column}}>
        {{#each this.options as |opt|}}
          <option value={{opt}}>{{opt}}</option>
        {{/each}}
      </select>
    </label>
  </template>
}

interface FormFilters {
  [column: string]: string[];
}

class DynamicTable extends Component<{ headers: string[]; rows: string[][] }> {
  @tracked declare filters: FormFilters;

  handleChange = (newValues: FormFilters) => {
    console.log(newValues);
    this.filters = newValues;
  };

  get filtered() {
    const { rows, headers } = this.args;

    if (!this.filters) {
      return rows;
    }

    console.log('trying to filter');

    return rows.filter((row) => {
      return row.every((column, index) => {
        const header = headers[index];

        if (!header) return true;

        const filter = this.filters[header];
        console.log('1', this.filters, filter);

        if (!filter) return true;
        if (filter?.length === 0) return true;

        return filter.some((filter) => filter === column);
      });
    });
  }

  <template>
    {{log this.filters}}

    <section class="filters">
      <h2>Filters</h2>
      <Form @onChange={{this.handleChange}}>
        {{#each @headers as |header|}}
          <Filters @column={{header}} @headers={{@headers}} @rows={{@rows}} />
        {{/each}}
      </Form>
    </section>

    <table>
      <thead>
        <tr>
          {{#each @headers as |heading|}}
            <th>
              {{heading}}
            </th>
          {{/each}}
        </tr>
      </thead>
      <tbody>
        {{#each this.filtered as |row|}}
          <tr>
            {{#each row as |datum|}}
              <td>{{datum}}</td>
            {{/each}}
          </tr>
        {{/each}}
      </tbody>
    </table>
  </template>
}

export default <template>
  {{pageTitle "table.md"}}

  <Header />

  <main>
    <DynamicTable @headers={{@model.headers}} @rows={{@model.rows}} />
  </main>
</template> satisfies TOC<{
  model: Model;
}>;
