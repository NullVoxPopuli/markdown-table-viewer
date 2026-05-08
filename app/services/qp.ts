import type RouterService from '@ember/routing/router-service';
import Service from '@ember/service';
import { service } from '@ember/service';

export type ColorValidation = [
  column: string,
  lowColor: string,
  highColor: string,
];

interface QPs {
  cv: ColorValidation[];
  hidden: string[];
  pinned: string[];
}

function tryParse<T>(raw: unknown, fallback: T): T {
  if (typeof raw !== 'string' || raw === '') return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch (e) {
    console.error(`Could not parse \`${raw}\``);
    console.error(e);
    return fallback;
  }
}

export default class QPService extends Service {
  @service declare router: RouterService;

  get #current() {
    return this.router.currentRoute?.queryParams ?? {};
  }

  get conditionalValidations(): QPs['cv'] {
    return tryParse<QPs['cv']>(this.#current.cv, []);
  }

  set conditionalValidations(value: QPs['cv']) {
    this.router.transitionTo({
      queryParams: {
        cv: value.length === 0 ? null : JSON.stringify(value),
      },
    });
  }

  get hiddenColumns(): QPs['hidden'] {
    return tryParse<QPs['hidden']>(this.#current.hidden, []);
  }

  set hiddenColumns(value: QPs['hidden']) {
    this.router.transitionTo({
      queryParams: {
        hidden: value.length === 0 ? null : JSON.stringify(value),
      },
    });
  }

  setColorRange(column: string, low: string | null, high: string | null) {
    const next = this.conditionalValidations.filter((v) => v[0] !== column);
    if (low && high) next.push([column, low, high]);
    this.conditionalValidations = next;
  }

  toggleColumn(column: string, visible: boolean) {
    const current = new Set(this.hiddenColumns);
    if (visible) current.delete(column);
    else current.add(column);
    this.hiddenColumns = [...current];
  }

  isHidden(column: string): boolean {
    return this.hiddenColumns.includes(column);
  }

  colorRangeFor(column: string): ColorValidation | undefined {
    return this.conditionalValidations.find((v) => v[0] === column);
  }

  get pinnedRows(): QPs['pinned'] {
    return tryParse<QPs['pinned']>(this.#current['pinned'], []);
  }

  set pinnedRows(value: QPs['pinned']) {
    this.router.transitionTo({
      queryParams: {
        pinned: value.length === 0 ? null : JSON.stringify(value),
      },
    });
  }

  isPinned(rowId: string): boolean {
    return this.pinnedRows.includes(rowId);
  }

  togglePin(rowId: string) {
    const current = new Set(this.pinnedRows);
    if (current.has(rowId)) current.delete(rowId);
    else current.add(rowId);
    this.pinnedRows = [...current];
  }

  unpinAll() {
    this.pinnedRows = [];
  }
}
