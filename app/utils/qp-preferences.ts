import type RouterService from '@ember/routing/router-service';
import type {
  PreferencesAdapter,
  PreferencesData,
} from '@universal-ember/table';

/**
 * Build a `PreferencesAdapter` for `@universal-ember/table` that reads
 * and writes the table's full preferences blob through a single query
 * param on the active route. With this in place every plugin that
 * speaks the preferences API (column visibility, sticky columns, etc.)
 * gets URL persistence and shareable links for free — the consumer no
 * longer has to mirror plugin-specific state into its own QPs.
 *
 * The blob is serialized as a JSON string under `paramName` (defaults
 * to `prefs`). When everything is at defaults, the param is removed
 * so URLs stay clean.
 */
export function createUrlPreferencesAdapter(
  router: RouterService,
  paramName = 'prefs'
): PreferencesAdapter {
  return {
    persist(key, data) {
      void key;
      const plugins = data?.plugins;
      const isEmpty = !plugins || Object.keys(plugins).length === 0;

      router.transitionTo({
        queryParams: { [paramName]: isEmpty ? null : JSON.stringify(data) },
      });
    },

    restore(key) {
      void key;
      const raw = router.currentRoute?.queryParams?.[paramName];
      if (typeof raw !== 'string' || raw === '') return undefined;
      try {
        return JSON.parse(raw) as PreferencesData;
      } catch (e) {
        console.error(`[qp-preferences] Could not parse \`${raw}\``);
        console.error(e);
        return undefined;
      }
    },
  };
}
