import Route from '@ember/routing/route';

export default class ErrorRoute extends Route {
  queryParams = { error: { refreshModel: true } };
  model(params: { error: string }) {
    return params;
  }
}
