import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';
import { colorScheme } from 'ember-primitives/color-scheme';

function isDark() {
  return colorScheme.isDark;
}

function toggle(event: MouseEvent) {
  const next = colorScheme.isDark ? 'light' : 'dark';

  if (typeof document.startViewTransition !== 'function') {
    colorScheme.update(next);
    return;
  }

  // Anchor the wipe at the cursor / toggle-button position so the
  // new theme appears to ripple out from where the user clicked.
  // CSS reads these via `var(--vt-x)` / `var(--vt-y)` on the
  // `::view-transition-new(root)` pseudo-element.
  document.documentElement.style.setProperty('--vt-x', `${event.clientX}px`);
  document.documentElement.style.setProperty('--vt-y', `${event.clientY}px`);

  document.startViewTransition(() => colorScheme.update(next));
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
