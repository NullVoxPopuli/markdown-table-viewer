import Component from '@glimmer/component';
import { Filter, FilterForm } from './filters.gts';
import { Sorter, Sorts } from './sorter.gts';
import { link } from 'reactiveweb/link';
import { parseInline } from 'marked';
import { service } from '@ember/service';
import type QPService from '#services/qp.ts';
import { cached } from '@glimmer/tracking';
import { colors } from '#colors';

function convertMarkdown(str: string): string {
  return parseInline(str, { gfm: true }) as string;
}

export class DynamicTable extends Component<{
  headers: string[];
  rows: string[][];
}> {
  @service declare qp: QPService;

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

  @cached
  get colors() {
    return colors(this.qp, {
      headers: this.args.headers,
      rows: this.args.rows,
    });
  }

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
            {{#each row as |datum index|}}
              {{! NOTE: not sanitized, because no user data is captured on this site.
                        Also, github sanitizes on save }}
              <td
                style="background: {{this.colors.for index datum}}"
              >{{{convertMarkdown datum}}}</td>
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
