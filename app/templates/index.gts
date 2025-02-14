import { DynamicTable } from '#components/dynamic-table.gts';
import type { Model } from '#routes/application.ts';
import type { TOC } from '@ember/component/template-only';

export default <template>
  <DynamicTable @headers={{@model.headers}} @rows={{@model.rows}} />
</template> satisfies TOC<{
  model: Model;
}>;
