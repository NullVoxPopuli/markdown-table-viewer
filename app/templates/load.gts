import Component from '@glimmer/component';
import type RouterService from '@ember/routing/router-service';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { dataFromEvent } from 'ember-primitives/components/form';
import { urlToRaw } from '#utils';
import { tracked } from '@glimmer/tracking';
import { LinkTo } from '@ember/routing';

class Form extends Component {
  @service declare router: RouterService;

  @tracked error: undefined | string;

  handleSubmit = (submitEvent: SubmitEvent) => {
    submitEvent.preventDefault();
    this.error = undefined;

    try {
      const data = dataFromEvent(submitEvent);

      const raw = urlToRaw(String(data.url));

      // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
      const url = `/?file=${raw}&key=${data.key}`;
      this.router.transitionTo(url);
    } catch (e) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      this.error = e.message;
    }
  };

  <template>
    <form {{on "submit" this.handleSubmit}} class="load-form">
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

      <span class="buttons">
        <input type="reset" value="Clear" aria-label="Clear form" />
        <button type="submit">Submit</button>
      </span>
    </form>
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

  <Form />
</template>
