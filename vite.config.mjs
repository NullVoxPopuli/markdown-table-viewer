import { defineConfig } from 'vite';
import { extensions, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';

const validator = `${process.cwd()}/node_modules/ember-source/dist/packages/@glimmer/validator/index.js`;
const tracking = `${process.cwd()}/node_modules/ember-source/dist/packages/@glimmer/tracking/index.js`;

export default defineConfig({
  resolve: {
    extensions,
    alias: {
      '@glimmer/validator': validator,
      '@glimmer/tracking': tracking,
    },
  },
  plugins: [
    ember(),
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
  ],
});
