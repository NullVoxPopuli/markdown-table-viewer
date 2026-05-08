import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';
import { colorScheme } from 'ember-primitives/color-scheme';

function isDark() {
  return colorScheme.isDark;
}

function toggle() {
  colorScheme.update(colorScheme.isDark ? 'light' : 'dark');
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
