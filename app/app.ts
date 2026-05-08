import Application from '@ember/application';
import Resolver from 'ember-resolver';
import { sync as syncColorScheme } from 'ember-primitives/color-scheme';
import config from './config/environment';

import { registry } from './registry.ts';

syncColorScheme();

export default class App extends Application {
  modulePrefix = config.modulePrefix;
  podModulePrefix = config.podModulePrefix;
  Resolver = Resolver.withModules(registry);
}
