import Component from '@glimmer/component';
import { Filter, FilterForm } from './filters.gts';
import { Sorter, Sorts } from './sorter.gts';
import { link } from 'reactiveweb/link';

export class DynamicTable extends Component<{
  headers: string[];
  rows: string[][];
}> {
  // Bug? this should be safe
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call
  @link filter = new Filter({
    data: () => this.args.rows,
    headers: () => this.args.headers,
  });

  // Bug? this should be safe
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call
  @link sorter = new Sorter({
    // Bug? this should be safe
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-member-access
    data: () => this.filter.data,
    headers: () => this.args.headers,
  });

  <template>
    <FilterForm @filters={{this.filter}} />

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
