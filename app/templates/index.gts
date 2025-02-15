import { DynamicTable } from '#components/dynamic-table.gts';
import type { Model } from '#routes/index.ts';
import type { TOC } from '@ember/component/template-only';

export default <template>
  <p class="small">viewing
    <a
      href={{@model.file}}
      target="_blank"
      rel="noopener noreferrer"
    >{{@model.file}}</a>
  </p>
  <br />
  <DynamicTable @headers={{@model.data.headers}} @rows={{@model.data.rows}} />
</template> satisfies TOC<{
  model: Model;
}>;
