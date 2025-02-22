import { LinkTo } from '@ember/routing';

export const Header = <template>
  <header>
    <span>
      <span>
        <LinkTo @route="application" class="home-link">
          table.md viewer
        </LinkTo>
        <LinkTo @route="load" class="home-link" title="Load another table">
          ⇆
        </LinkTo>
      </span>
      <span>
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
