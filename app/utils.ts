/* eslint-disable @typescript-eslint/no-unused-vars */
const github = {
  suffixVariants: ['', '/', '/tree/main', '/blob/main/README.md'],
  domains: {
    raw: 'raw.githubusercontent.com',
    app: 'github.com',
  },
};

/**
 * If the URL has a github.com domain,
 * return the raw.githubusercontent equiv
 */
export function urlToRaw(url: string) {
  const parsed = new URL(url);
  const { host, pathname, search, protocol } = parsed;

  if (host === github.domains.app) {
    const [org, repo, ...parts] = pathname
      .split('/')
      .map((x) => x.trim())
      .filter(Boolean);

    let updatedPath = '';

    /**
     * https://github.com/NullVoxPopuli/disk-perf-git-and-pnpm/
     *                   ^ org          ^ repo                ^ ...parts
     */
    if (parts.length === 0) {
      updatedPath = `${org}/${repo}/refs/heads/main/README.md`;
    } else if (parts[0] === 'blob') {
      /**
       * https://github.com/emberjs/data/blob/main/guides/manual/1-overview.md
       *                    ^ org   ^repo
       *                                 ^[0]
       */
      const [blob, branch, ...pathParts] = parts;

      updatedPath = `${org}/${repo}/refs/heads/${branch}/${pathParts.join('/')}`;
    } else if (parts[0] === 'tree') {
    /**
     * Missing the README:
     *
       * https://github.com/emberjs/data/tree/main
       *                    ^ org   ^repo
       *                                 ^[0]
       */
    const [tree, branch, ...pathParts] = parts;
    updatedPath = `${org}/${repo}/refs/heads/${branch}/${[...pathParts, 'README.md'].join('/')}`;

    } else {
      updatedPath = pathname.replace('/tree/', '/blob/');
    }

    updatedPath = updatedPath.replace(/^\//, '');

    return `${protocol}//${github.domains.raw}/${updatedPath}${search}`;
  }

  return url;
}

/**
 * If the URL has a raw.githubusercontent domain,
 * return  the github.com variant of the URL
 */
export function unRaw(url: string) {
  const parsed = new URL(url);
  const { host, pathname, search, protocol } = parsed;

  if (host === github.domains.raw) {
    const updatedPath = pathname.replace('/refs/heads/', '/blob/');

    return `${protocol}//${github.domains.app}${updatedPath}${search}`;
  }

  // Unknown HOST, we can add to this function over time.
  return url;
}

if (import.meta.vitest) {
  const { describe, it, expect } = import.meta.vitest;

  const raw = {
    disk: 'https://raw.githubusercontent.com/NullVoxPopuli/disk-perf-git-and-pnpm/refs/heads/main/README.md',
    dataOverview:
      'https://raw.githubusercontent.com/emberjs/data/refs/heads/main/guides/manual/1-overview.md',
  };

  describe('urlToRaw (default)', () => {
    const examples = [
      ['https://github.com/NullVoxPopuli/disk-perf-git-and-pnpm', raw.disk],

    ] as const;

    for (const variant of github.suffixVariants) {
      describe(variant, () => {
        for (const example of examples) {
          it(example[0], () => {
            const [input, expected] = example;
            const result = urlToRaw(input + variant);
            expect(result.split('/')).toEqual(expected.split('/'));
          });
        }
      });
    }
  });

  describe('urlToRaw (long path)', () => {
    const examples = [
      [
        'https://github.com/emberjs/data/blob/main/guides/manual/1-overview.md',
        raw.dataOverview,
      ],
    ] as const;

        for (const example of examples) {
          it(example[0], () => {
            const [input, expected] = example;
            const result = urlToRaw(input);
            expect(result.split('/')).toEqual(expected.split('/'));
          });
        }
  });

  describe('unRaw', () => {
    const examples = [
      [
        raw.dataOverview,
        'https://github.com/emberjs/data/blob/main/guides/manual/1-overview.md',
      ],
      [
        raw.disk,
        'https://github.com/NullVoxPopuli/disk-perf-git-and-pnpm/blob/main/README.md',
      ],
    ] as const;

    it('it works', () => {
      for (const example of examples) {
        const [input, expected] = example;
        const result = unRaw(input);
        expect(result.split('/')).toEqual(expected.split('/'));
      }
    });
  });
}
