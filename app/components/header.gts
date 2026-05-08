import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';
import { colorScheme } from 'ember-primitives/color-scheme';

function isDark() {
  return colorScheme.isDark;
}

function toggle() {
  const next = colorScheme.isDark ? 'light' : 'dark';
  // View Transitions API: snapshot current paint, flip the theme,
  // snapshot the new paint, then cross-fade the two as a single
  // page-level animation. Falls back to an instant swap on browsers
  // that don't support the API (currently Firefox without the flag).
  if (typeof document.startViewTransition === 'function') {
    document.startViewTransition(() => colorScheme.update(next));
  } else {
    colorScheme.update(next);
  }
}

export const Header = <template>
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
