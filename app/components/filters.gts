import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';

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
