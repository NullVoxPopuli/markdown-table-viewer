import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';
import { colorScheme } from 'ember-primitives/color-scheme';

function isDark() {
  return colorScheme.isDark;
}

/*
 * ember-primitives writes `style="color-scheme: dark"` on <html> and
 * round-trips it to localStorage, but we can't select on inline-style
 * declarations from CSS. lightning-css (Vite's CSS pipeline) also
 * ships an inconsistent `light-dark()` implementation, so anything
 * built on top of it ends up with empty variable values.
 *
 * Mirror the live theme onto a `data-theme` attribute instead — it's
 * a plain selector target every CSS engine handles, and the helper is
 * called from the template so it re-runs whenever `colorScheme.current`
 * (a tracked value) changes.
 */
function syncDataTheme() {
  const root = document.documentElement;
  root.dataset['theme'] = colorScheme.isDark ? 'dark' : 'light';
}

function toggle() {
  colorScheme.update(colorScheme.isDark ? 'light' : 'dark');
}

export const Header = <template>
  {{ (syncDataTheme) }}
  <header>
    <span>
      <LinkTo @route="application" class="home-link">
        table.md viewer
      </LinkTo>
      <span class="header-actions">
        <button
          type="button"
          class="theme-toggle"
          aria-label={{if
            (isDark)
            "Switch to light theme"
            "Switch to dark theme"
          }}
          title={{if (isDark) "Switch to light theme" "Switch to dark theme"}}
          {{on "click" toggle}}
        >
          <span aria-hidden="true">{{if (isDark) "☀" "🌙"}}</span>
        </button>
        <a
          href="https://github.com/NullVoxPopuli/markdown-table-viewer"
          target="_blank"
          rel="noopener noreferrer"
        >
          GitHub
        </a>
      </span>
    </span>
  </header>
</template>;
