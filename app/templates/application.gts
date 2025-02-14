import { Header } from '#components/header.gts';
import type { TOC } from '@ember/component/template-only';
import { pageTitle } from 'ember-page-title';
import type { Model } from '#routes/application.ts';

export default <template>
  {{pageTitle "table.md"}}

  <Header />

  <main>
    {{outlet}}
  </main>
</template> satisfies TOC<{
  model: Model;
}>;
