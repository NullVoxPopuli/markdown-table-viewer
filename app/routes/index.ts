import Route from '@ember/routing/route';
import type RouterService from '@ember/routing/router-service';
import type Transition from '@ember/routing/transition';
import { service } from '@ember/service';

export interface Model {
  headers: string[];
  rows: string[][];
}

export default class IndexRoute extends Route {
  @service declare router: RouterService;

  queryParams = {
    file: { refreshModel: true },
    key: { refreshModel: true },
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
    console.log('Parsed QPs', { file, key });

    const response = await fetch(file);
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

  let start = lines.findIndex((line) => line.startsWith(key));

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
