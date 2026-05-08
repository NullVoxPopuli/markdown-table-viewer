import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import type ThemeService from '#services/theme.ts';

export class Header extends Component {
  @service declare theme: ThemeService;

  get nextLabel() {
    return this.theme.current === 'dark'
      ? 'Switch to light theme'
      : 'Switch to dark theme';
  }

  get icon() {
    return this.theme.current === 'dark' ? '☀' : '🌙';
  }

  <template>
    <header>
      <span>
        <LinkTo @route="application" class="home-link">
          table.md viewer
        </LinkTo>
        <span class="header-actions">
          <button
            type="button"
            class="theme-toggle"
            aria-label={{this.nextLabel}}
            title={{this.nextLabel}}
            {{on "click" this.theme.toggle}}
          >
            <span aria-hidden="true">{{this.icon}}</span>
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
  </template>
}
