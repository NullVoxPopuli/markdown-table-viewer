import type RouterService from '@ember/routing/router-service';
import Service from '@ember/service';
import { service } from '@ember/service';

interface QPs {
  cv: [column: string, lowColor: string, highColor: string][];
}

export default class QPService extends Service {
  @service declare router: RouterService;

  get #current() {
    return this.router.currentRoute?.queryParams ?? {};
  }

  get conditionalValidations(): QPs['cv'] | undefined {
    const raw = this.#current.cv as string;

    try {
      return JSON.parse(raw) as QPs['cv'];
    } catch (e) {
      console.error(`Could not parse \`${raw}\``);
      console.error(e);
    }
  }
  set conditionalValidations(value: QPs['cv']) {
    this.router.transitionTo({
      queryParams: {
        cv: JSON.stringify(value),
      },
    });
  }
}
