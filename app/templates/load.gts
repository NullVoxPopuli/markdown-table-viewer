import Component from '@glimmer/component';
import type RouterService from '@ember/routing/router-service';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { Form } from 'ember-primitives/components/form';
import { urlToRaw } from '#utils';
import { tracked } from '@glimmer/tracking';
import { LinkTo } from '@ember/routing';
import { TrackedArray } from 'tracked-built-ins';
import { fn } from '@ember/helper';

type Data = Record<
  | 'url'
  | 'key'
  | `cv[${number}].name`
  | `cv[${number}].start`
  | `cv[${number}].end`,
  string
>;

class Configure extends Component {
  @service declare router: RouterService;

  @tracked error: undefined | string;
  @tracked data: Data = {};
  @tracked url = '';

  handleUpdate = (data: Data) => {
    this.error = '';
    this.url = '';

    try {
      this.data = data;
      console.log({ data });

      const raw = urlToRaw(String(data.url));

      const url = `/?file=${raw}&key=${data.key}`;
      this.url = url;
    } catch (e) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      this.error = e.message;
    }
  };

  handleSubmit = (event: Event) => {
    event.preventDefault();

    // this.router.transitionTo(this.url);
  };

  cvFields = new TrackedArray([1]);
  addCVField = () => this.cvFields.push(this.cvFields.length);
  removeCVField = (i: number) => this.cvFields.splice(i);

  dataFor = (...fields: string[]) => {
    // if (!this.data) return;
    //
    // let key = fields.shift();
    // let result = this.data;
    // while (key) {
    //   result = result?.[key];
    // }
    //
    // return result;
  };

  <template>
    <fieldset class="load-fields"><legend>Configure your table</legend>
      <Form
        @onChange={{this.handleUpdate}}
        {{on "submit" this.handleSubmit}}
        class="load-form"
      >
        {{#if this.error}}
          <div class="error">
            {{this.error}}
          </div>
        {{/if}}

        <label class="url">
          <span>URL to markdown document containing a table</span>
          <input required type="text" name="url" autocomplete="off" />
        </label>

        <label class="key">
          <span>Optional first few characters of the table heading<br />
            <span class="small">(if there are multiple tables in the document)</span></span>
          <input type="text" name="key" autocomplete="off" />
        </label>

        <div class="list-maker">
          <div class="heading">
            <span>Conditional Highlighting</span>
            <button type="button" {{on "click" this.addCVField}}>Add Field</button>
          </div>

          <ul>
            {{#each this.cvFields as |_ i|}}
              <li>
                <div class="form-cv">
                  <span>
                    <label>Field Name
                      <input type="text" name="cv[{{i}}].name" />
                    </label>
                    <label>
                      <span>Lowest Color</span>
                      <input type="text" name="cv[{{i}}].start" />
                      <span
                        class="color-result"
                        style="--bg: {{this.dataFor 'cv' i 'start'}}"
                      ></span>
                    </label>
                    <label>
                      <span>Highest Color</span>
                      <input type="text" name="cv[{{i}}].end" />
                      <span
                        class="color-result"
                        style="--bg: {{this.dataFor 'cv' i 'end'}}"
                      ></span>
                    </label>
                  </span>
                  <button
                    type="button"
                    {{on "click" (fn this.removeCVField i)}}
                  >Remove</button>
                </div>
              </li>
            {{/each}}
          </ul>

        </div>

        <span class="buttons">
          <input type="reset" value="Clear" aria-label="Clear form" />
          <button type="submit">Submit</button>
        </span>
      </Form>
    </fieldset>

    <details open><summary>Debug</summary>
      <pre>{{globalThis.JSON.stringify this.data null 2}}</pre>
      Will redirect to:
      <pre>{{this.url}}</pre>
    </details>
  </template>
}
// https://markdown-table.nullvoxpopuli.com/?file=https%3A%2F%2Fraw.githubusercontent.com%2FNullVoxPopuli%2Fdisk-perf-git-and-pnpm%2Frefs%2Fheads%2Fmain%2FREADME.md&key=&cv=%5B%5B%22%20Clean%20(s)%20%22%2C%22%2300aa00%22%2C%22%23aa0000%22%5D,%5B%22%20Install%20(s)%20%22%2C%22%2300aa00%22%2C%22%23aa0000%22%5D%5D
const sample = {
  file: 'https://raw.githubusercontent.com/NullVoxPopuli/disk-perf-git-and-pnpm/refs/heads/main/README.md',
  key: '| CPU |',
  cv: '[[" Clean (s) ", "#00aa00", "#aa0000"]]',
};

const Sample = <template>
  <span>
    Or:

    <LinkTo @route="index" @query={{sample}}>view a sample table instead</LinkTo>.
  </span>
</template>;

<template>
  <h1>
    Load a table from markdown
  </h1>

  <Sample />

  <Configure />
</template>
