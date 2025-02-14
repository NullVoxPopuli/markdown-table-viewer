import Component from '@glimmer/component';
import type RouterService from '@ember/routing/router-service';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { dataFromEvent } from 'ember-primitives/components/form';

class Form extends Component {
  @service declare router: RouterService;

  handleSubmit = (submitEvent: SubmitEvent) => {
    submitEvent.preventDefault();

    const data = dataFromEvent(submitEvent);

    console.log(data);
  };

  <template>
    <form {{on "submit" this.handleSubmit}} class="load-form">
      <label class="url">
        <span>URL to markdown document containing a table</span>
        <input required type="text" name="url" />
      </label>

      <label class="key">
        <span>Optional first few characters of the table heading<br />
          <span class="small">(if there are multiple tables in the document)</span></span>
        <input type="text" name="key" />
      </label>

      <span class="buttons">
        <input type="reset" value="Clear" aria-label="Clear form" />
        <button type="submit">Submit</button>
      </span>
    </form>
  </template>
}

<template>
  <h1>
    Load a table from markdown
  </h1>

  <Form />
</template>
