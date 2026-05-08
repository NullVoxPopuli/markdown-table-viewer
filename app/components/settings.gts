import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { Popover } from 'ember-primitives/components/popover';

import type QPService from '#services/qp.ts';

interface ColumnConfig {
  name: string;
  key: string;
}

const DEFAULT_LOW = '#ff5252';
const DEFAULT_HIGH = '#5cd472';

function inputValue(event: Event): string {
  const t = event.target;
  if (t instanceof HTMLInputElement) return t.value;
  return '';
}

function isInputChecked(event: Event): boolean {
  const t = event.target;
  if (t instanceof HTMLInputElement) return t.checked;
  return false;
}

export class Settings extends Component<{
  Args: {
    columns: ColumnConfig[];
    numericFlags: boolean[];
  };
}> {
  @service declare qp: QPService;

  @tracked open = false;

  toggleOpen = () => (this.open = !this.open);

  isVisible = (header: string) => !this.qp.isHidden(header);

  isHighlighted = (header: string) =>
    this.qp.colorRangeFor(header) !== undefined;

  lowColorOf = (header: string) =>
    this.qp.colorRangeFor(header)?.[1] ?? DEFAULT_LOW;

  highColorOf = (header: string) =>
    this.qp.colorRangeFor(header)?.[2] ?? DEFAULT_HIGH;

  toggleVisibility = (header: string, event: Event) => {
    this.qp.toggleColumn(header, isInputChecked(event));
  };

  toggleHighlight = (header: string, event: Event) => {
    if (isInputChecked(event)) {
      this.qp.setColorRange(header, DEFAULT_LOW, DEFAULT_HIGH);
    } else {
      this.qp.setColorRange(header, null, null);
    }
  };

  setLow = (header: string, event: Event) => {
    const high = this.qp.colorRangeFor(header)?.[2] ?? DEFAULT_HIGH;
    this.qp.setColorRange(header, inputValue(event), high);
  };

  setHigh = (header: string, event: Event) => {
    const low = this.qp.colorRangeFor(header)?.[1] ?? DEFAULT_LOW;
    this.qp.setColorRange(header, low, inputValue(event));
  };

  showAll = () => {
    this.qp.hiddenColumns = [];
  };

  clearHighlights = () => {
    this.qp.conditionalValidations = [];
  };

  isNumeric = (key: string) => {
    const idx = parseInt(key.replace(/^col/, ''), 10);
    return this.args.numericFlags[idx] ?? false;
  };

  <template>
    <Popover @placement="bottom-end" @offsetOptions={{8}} as |p|>
      <button
        type="button"
        class="settings-trigger"
        aria-label="Open settings"
        aria-expanded="{{this.open}}"
        {{p.reference}}
        {{on "click" this.toggleOpen}}
      >
        <span aria-hidden="true">⚙</span>
        Settings
      </button>

      {{#if this.open}}
        <p.Content @as="dialog" class="settings-popover">
          <div class="settings-header">
            <h3>Table Settings</h3>
            <button
              type="button"
              class="icon-btn"
              aria-label="Close settings"
              {{on "click" this.toggleOpen}}
            >×</button>
          </div>

          <div class="settings-actions">
            <button
              type="button"
              class="link-btn"
              {{on "click" this.showAll}}
            >Show all columns</button>
            <button
              type="button"
              class="link-btn"
              {{on "click" this.clearHighlights}}
            >Clear all highlighting</button>
          </div>

          <ul class="settings-columns">
            {{#each @columns as |col|}}
              <li class="settings-row">
                <label class="visibility">
                  <input
                    type="checkbox"
                    checked={{this.isVisible col.name}}
                    {{on "change" (fn this.toggleVisibility col.name)}}
                  />
                  <span class="col-name">{{col.name}}</span>
                </label>

                {{#if (this.isNumeric col.key)}}
                  <div class="highlight-controls">
                    <label class="highlight-toggle">
                      <input
                        type="checkbox"
                        checked={{this.isHighlighted col.name}}
                        {{on "change" (fn this.toggleHighlight col.name)}}
                      />
                      Color
                    </label>
                    {{#if (this.isHighlighted col.name)}}
                      <span class="color-pickers">
                        <input
                          type="color"
                          aria-label="Low color for {{col.name}}"
                          value={{this.lowColorOf col.name}}
                          {{on "change" (fn this.setLow col.name)}}
                        />
                        <span class="arrow" aria-hidden="true">→</span>
                        <input
                          type="color"
                          aria-label="High color for {{col.name}}"
                          value={{this.highColorOf col.name}}
                          {{on "change" (fn this.setHigh col.name)}}
                        />
                      </span>
                    {{/if}}
                  </div>
                {{/if}}
              </li>
            {{/each}}
          </ul>
        </p.Content>
      {{/if}}
    </Popover>
  </template>
}
