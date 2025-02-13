import type { TOC } from '@ember/component/template-only';
import { pageTitle } from 'ember-page-title';

export default <template>
  {{pageTitle "table.md"}}

  <main>
    <table>
      <thead>
        <tr>
          {{#each @model.headers as |heading|}}
            <th>{{heading}}</th>
          {{/each}}
        </tr>
      </thead>
      <tbody>
        {{#each @model.rows as |row|}}
          <tr>
            {{#each row as |datum|}}
              <td>{{datum}}</td>
            {{/each}}
          </tr>
        {{/each}}
      </tbody>
    </table>
  </main>
</template> satisfies TOC<{
  headers: string[];
  rows: string[][];
}>;
