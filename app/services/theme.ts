import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

export type Theme = 'light' | 'dark';

const STORAGE_KEY = 'table-viewer-theme';

function readStored(): Theme | undefined {
  try {
    const v = localStorage.getItem(STORAGE_KEY);
    if (v === 'light' || v === 'dark') return v;
  } catch {
    /* localStorage may be unavailable */
  }
  return undefined;
}

function systemPreference(): Theme {
  if (
    typeof window !== 'undefined' &&
    window.matchMedia('(prefers-color-scheme: dark)').matches
  ) {
    return 'dark';
  }
  return 'light';
}

export default class ThemeService extends Service {
  @tracked current: Theme = readStored() ?? systemPreference();

  constructor(...args: unknown[]) {
    // @ts-expect-error - forwarding constructor args to Service
    super(...args);
    this.#apply(this.current);
  }

  setTheme = (theme: Theme) => {
    this.current = theme;
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch {
      /* ignore */
    }
    this.#apply(theme);
  };

  toggle = () => {
    this.setTheme(this.current === 'dark' ? 'light' : 'dark');
  };

  #apply(theme: Theme) {
    if (typeof document === 'undefined') return;
    document.documentElement.dataset['theme'] = theme;
  }
}
