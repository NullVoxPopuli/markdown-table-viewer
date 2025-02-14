import Component from '@glimmer/component';

export class Filters extends Component<{
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
