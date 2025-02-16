import type RouterService from '@ember/routing/router-service';
import Service from '@ember/service';
import { service } from '@ember/service';

import {
  compressToEncodedURIComponent,
  decompressFromEncodedURIComponent,
} from 'lz-string';

interface ParsedQPs {
  // conditional validations
  // aka set a background color based on the range of the data
  // for the column
  cv: [column: string, lowColor: string, highColor: string][];
  // Only one column can be sorted at a time
  sort: null | [column: string, direction: 'asc' | 'desc'];
  // for each column, filter on values or partial match
  filter: null | { [column: string]: string | string[] };
  // The headers listed in a new order
  order: null | string[];
}

const DEFAULT_CONFIG: ParsedQPs = {
  cv: [],
  sort: null,
  filter: null,
  order: null,
};

interface UnparsedQPs {
  [key: string]: string;
}

type QueryParams = Record<string, string | number | undefined>;

/**
 * The Query Params for this app can get kinda crazy,
 * so everything that isn't the `file` QP is combined into a
 * JSON object, and then gone through LZString (what many REPLs use)
 * for compression.
 *
 * This is needed because we need data structures in the QPs, and certain characters,
 * like `[`, `]`, break many URL parsers on social sites.
 */
export default class QPService extends Service {
  @service declare router: RouterService;

  get #current(): UnparsedQPs {
    return (this.router.currentRoute?.queryParams ?? {}) as UnparsedQPs;
  }

  get file(): string | undefined {
    const file = this.#current.file;

    if (typeof file === 'string') return file;
  }

  get cv() {
    return this.config.cv;
  }
  set cv(value: ParsedQPs['cv']) {
    this.#updateConfig('cv', value);
  }

  get sort() {
    return this.config.sort;
  }
  set sort(value: ParsedQPs['sort']) {
    this.#updateConfig('sort', value);
  }
  get filter() {
    return this.config.filter;
  }
  set filter(value: ParsedQPs['filter']) {
    this.#updateConfig('filter', value);
  }
  get order() {
    return this.config.order;
  }
  set order(value: ParsedQPs['order']) {
    this.#updateConfig('order', value);
  }

  get config(): ParsedQPs {
    const compressed = this.#current.config;

    if (compressed) {
      const json = decompressFromEncodedURIComponent(compressed);
      const config = JSON.parse(json);

      // hopefully
      return config as unknown as ParsedQPs;
    }

    return DEFAULT_CONFIG;
  }

  #updateConfig<Key extends keyof ParsedQPs>(key: Key, value: ParsedQPs[Key]) {
    this.#setConfig({
      ...this.config,
      [key]: value,
    });
  }

  #setConfig(config: ParsedQPs) {
    const json = JSON.stringify(config);
    const str = compressToEncodedURIComponent(json);

    this.#setQP({
      config: str,
    });
  }

  /**
   * Allows batching QP updates
   */
  #frame?: number;
  #qps?: QueryParams;
  #setQP = (qps: QueryParams) => {
    if (this.#frame) cancelAnimationFrame(this.#frame);

    this.#qps = {
      ...this.#current,
      ...this.#qps,
      ...qps,
    };

    this.#frame = requestAnimationFrame(() => {
      this.router.transitionTo({
        queryParams: this.#qps,
      });
    });
  };
}
