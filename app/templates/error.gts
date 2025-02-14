import type { TOC } from '@ember/component/template-only';
import { LinkTo } from '@ember/routing';

export default <template>
  <div class="error">
    <pre>{{@model.error}}</pre>
  </div>

  <LinkTo @route="load">Try again</LinkTo>
</template> satisfies TOC<{ model: { error: string } }>;
