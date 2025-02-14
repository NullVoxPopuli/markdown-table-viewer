import { LinkTo } from '@ember/routing';

export const Header = <template>
  <header>
    <span>
      <LinkTo @route="application" class="home-link">
        table.md viewer
      </LinkTo>
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

  <style>
    header {
      width: 100%;
      height: 64px;
      position: sticky;
      top: 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;

      > span {
        margin: 0 auto;
        max-width: 800px;
        min-width: 500px;
        display: flex;
        justify-content: space-between;
      }
    }
  </style>
</template>;
