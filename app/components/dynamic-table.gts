import Component from '@glimmer/component';
import { Filter, FilterForm } from './filters.gts';
import { Sorter, Sorts } from './sorter.gts';
import { link } from 'reactiveweb/link';
import { parseInline } from 'marked';
import { interpolate } from 'culori';
import { service } from '@ember/service';
import type QPService from '#services/qp.ts';

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

  colorFor = (hIndex: number, value: string) => {
    if (!value) return;
    const heading = this.args.headers[hIndex];
    if (!heading) return;
    let num = parseFloat(value);

    if (isNaN(num)) return;

    const validation = this.qp.conditionalValidations?.find(
      (v) => v[0] === heading
    );
    if (!validation) return;

    const interpolation = this.getInterpolation(
      hIndex,
      validation[1],
      validation[2]
    );

    const max = this.maxOf(hIndex);
    const min = this.minOf(hIndex);
    const normalized = (num - min) / (max - min);
    const color = interpolation(normalized);

    return `oklch(${color.l} ${color.c} ${color.h}deg)`;
  };

  #maxCache = {};
  #minCache = {};
  maxOf = (hIndex: number) => {
    if (this.#maxCache[hIndex]) return this.#maxCache[hIndex];

    const values = this.args.rows
      .map((row) => row[hIndex])
      .map((x) => parseFloat(x));
    return Math.max(...values);
  };
  minOf = (hIndex: number) => {
    if (this.#minCache[hIndex]) return this.#minCache[hIndex];
    const values = this.args.rows
      .map((row) => row[hIndex])
      .map((x) => parseFloat(x));
    return Math.min(...values);
  };

  #interpolationCache = {};
  getInterpolation(hIndex: number, end: string, start: string) {
    if (this.#interpolationCache[hIndex])
      return this.#interpolationCache[hIndex];

    const interpolation = interpolate([end, start], 'oklch');

    this.#interpolationCache[hIndex] = interpolation;
    return interpolation;
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
                style="background: {{this.colorFor index datum}}"
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
