import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { Popover } from 'ember-primitives/components/popover';

import { meta } from '@universal-ember/table/plugins';
import {
  ColumnVisibility,
  isVisible,
  isHidden,
} from '@universal-ember/table/plugins/column-visibility';
import type { Column, Table } from '@universal-ember/table';

import type QPService from '#services/qp.ts';

const DEFAULT_LOW = '#ff5252';
const DEFAULT_HIGH = '#5cd472';

function inputValue(event: Event): string {
  const t = event.target;
  if (t instanceof HTMLInputElement) return t.value;
  return '';
}

export class Settings<T> extends Component<{
  Args: {
    table: Table<T>;
    /** Whether `key` looks numeric — drives whether the color toggle shows. */
    isNumeric: (key: string) => boolean;
  };
}> {
  @service declare qp: QPService;

  @tracked open = false;

  toggleOpen = () => (this.open = !this.open);

  /** Every configured column, including ones the visibility plugin is hiding. */
  get allColumns(): Column<T>[] {
    return this.args.table.columns.values();
  }

  isVisible = (column: Column<T>) => isVisible(column);

  toggleVisibility = (column: Column<T>) => {
    meta.forColumn(column, ColumnVisibility).toggle();
  };

  showAll = () => {
    for (const column of this.allColumns) {
      if (isHidden(column)) {
        meta.forColumn(column, ColumnVisibility).show();
      }
    }
  };

  // Color highlighting still lives in the QP service: no plugin owns it.
  isHighlighted = (header: string | undefined) =>
    !!header && this.qp.colorRangeFor(header) !== undefined;

  lowColorOf = (header: string | undefined) =>
    (header && this.qp.colorRangeFor(header)?.[1]) ?? DEFAULT_LOW;

  highColorOf = (header: string | undefined) =>
    (header && this.qp.colorRangeFor(header)?.[2]) ?? DEFAULT_HIGH;

  toggleHighlight = (header: string | undefined, event: Event) => {
    if (!header) return;
    const target = event.target as HTMLInputElement;
    if (target.checked) {
      this.qp.setColorRange(header, DEFAULT_LOW, DEFAULT_HIGH);
    } else {
      this.qp.setColorRange(header, null, null);
    }
  };

  setLow = (header: string | undefined, event: Event) => {
    if (!header) return;
    const high = this.qp.colorRangeFor(header)?.[2] ?? DEFAULT_HIGH;
    this.qp.setColorRange(header, inputValue(event), high);
  };

  setHigh = (header: string | undefined, event: Event) => {
    if (!header) return;
    const low = this.qp.colorRangeFor(header)?.[1] ?? DEFAULT_LOW;
    this.qp.setColorRange(header, low, inputValue(event));
  };

  swapColors = (header: string | undefined) => {
    if (!header) return;
    const cv = this.qp.colorRangeFor(header);
    if (!cv) return;
    this.qp.setColorRange(header, cv[2], cv[1]);
  };

  clearHighlights = () => {
    this.qp.conditionalValidations = [];
  };

  isNumeric = (column: Column<T>) => this.args.isNumeric(column.key);

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
            {{#each this.allColumns as |col|}}
              <li class="settings-row">
                <label class="visibility">
                  <input
                    type="checkbox"
                    checked={{this.isVisible col}}
                    {{on "change" (fn this.toggleVisibility col)}}
                  />
                  <span class="col-name">{{col.name}}</span>
                </label>

                {{#if (this.isNumeric col)}}
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
                        <button
                          type="button"
                          class="color-swap"
                          aria-label="Swap colors for {{col.name}}"
                          title="Swap colors"
                          {{on "click" (fn this.swapColors col.name)}}
                        ><span aria-hidden="true">⇄</span></button>
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
