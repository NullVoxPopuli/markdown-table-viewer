import { assert } from '@ember/debug';
import Route from '@ember/routing/route';

export default class ApplicationRoute extends Route {
  queryParams = {
    file: { refreshModel: true },
    key: { refreshModel: true },
  };

  async model({ file, key }: { file: string; key: string }) {
    assert(`file is a required query param`, file);

    const response = await fetch(file);
    const text = await response.text();

    const data = findTable(text, key);

    console.log('Parsed table', data);

    return data;
  }
}

/**
 * Without a key, this will find the first table
 *
 * Should probably use a real parser, but this is 0 dependencies
 */
function findTable(text: string, key: string | undefined) {
  const lines = text.split('\n');

  const start = lines.findIndex((line) => line.startsWith(key));

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
