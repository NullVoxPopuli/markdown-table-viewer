import Route from '@ember/routing/route';
import type RouterService from '@ember/routing/router-service';
import type Transition from '@ember/routing/transition';
import { service } from '@ember/service';

export interface Model {
  data: {
    headers: string[];
    rows: string[][];
  };
  file: string;
}

interface Params {
  file: string;
  key: string;
}

export default class IndexRoute extends Route {
  @service declare router: RouterService;

  queryParams = {
    file: { refreshModel: true },
    key: { refreshModel: true },
    // post-fetch customizations
    cv: { /* custom validations */ refreshModel: false },
    // Not implemented yet, but should be
    sort: { refreshModel: false },
    filter: { refreshModel: false },
  };

  beforeModel(transition: Transition) {
    const { to } = transition;
    const { queryParams } = to ?? {};

    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
    const file = (queryParams as any)?.file;

    if (!file) {
      transition.abort();
      this.router.transitionTo('load');
    }
  }

  async model({ file, key }: { file: string; key: string }): Promise<Model> {
    return await this.withErrorHandling({ file, key });
  }

  async withErrorHandling(params: Params) {
    try {
      const response = await this.load(params);

      if (!response) throw new Error(`Could not load or parse data`);

      return response;
    } catch (e) {
      this.handleError(e);
      throw e;
    }
  }

  handleError(e: unknown) {
    if (typeof e === 'object' && e !== null) {
      if ('message' in e && typeof e.message === 'string') {
        this.router.transitionTo(`/error?error=${e.message}`);
        return;
      }
    }

    this.router.transitionTo(`An unknown error occurred`);
  }

  async load({ file, key }: Params) {
    const response = await fetch(file);
    if (response.status >= 400) {
      throw new Error(`Could not load file :( \n Status ${response.status}.`);
    }
    const text = await response.text();

    const data = findTable(text, key);

    return { data, file };
  }
}

/**
 * Without a key, this will find the first table
 *
 * Should probably use a real parser, but this is 0 dependencies
 */
function findTable(text: string, key: string | undefined) {
  const lines = text.split('\n');

  let start = key ? lines.findIndex((line) => line.startsWith(key)) : 0;

  if (start <= 0) {
    start = lines.findIndex((line) => line.startsWith('|'));
  }

  const remaining = lines.slice(start);

  const table = [];

  for (const line of remaining) {
    if (!line.startsWith('|')) continue;

    table.push(line);
  }

  const [heading, , ...rowData] = table;

  // We don't .trim(), because there could be empty cells
  // e.g.: |    |
  const headers = heading.split('|').filter(Boolean);
  const rows = rowData.map((row) => row.split('|').filter(Boolean));

  return { headers, rows };
}
