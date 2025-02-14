import { Header } from '#components/header.gts';
import type { TOC } from '@ember/component/template-only';
import { pageTitle } from 'ember-page-title';
import type { Model } from '#routes/application.ts';
import { DynamicTable } from '#components/dynamic-table.gts';

export default <template>
  {{pageTitle "table.md"}}

  <Header />

  <main>
    <DynamicTable @headers={{@model.headers}} @rows={{@model.rows}} />
  </main>
</template> satisfies TOC<{
  model: Model;
}>;
