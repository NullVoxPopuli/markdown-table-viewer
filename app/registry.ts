import Router from './router.ts';
import PageTitleService from 'ember-page-title/services/page-title';

const appName = `table-viewer`;

function formatAsResolverEntries(imports: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(imports).map(([k, v]) => [
      k.replace(/\.g?(j|t)s$/, '').replace(/^\.\//, `${appName}/`),
      v,
    ])
  );
}

/**
 * A global registry is needed until:
 * - Services can be referenced via import paths (rather than strings)
 * - we design a new routing system
 */
const resolverRegistry = {
  ...formatAsResolverEntries(
    import.meta.glob('./templates/**/*.{gjs,gts,js,ts}', { eager: true })
  ),
  ...formatAsResolverEntries(
    import.meta.glob('./services/**/*.{js,ts}', { eager: true })
  ),
  ...formatAsResolverEntries(
    import.meta.glob('./routes/**/*.{js,ts}', { eager: true })
  ),
  [`${appName}/router`]: Router,
};

export const registry = {
  ...resolverRegistry,
  [`${appName}/services/page-title`]: PageTitleService,
};
