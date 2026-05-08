import { modifier } from 'ember-modifier';

/**
 * Set `--head-offset` on the modified element to the live height of the
 * passed selector match (default: `thead`). Pinned rows can then sticky
 * themselves at `top: var(--head-offset)` and stay just below the head
 * regardless of how the head re-flows (e.g. when filter widgets resize).
 */
export const stickyOffset = modifier(
  (
    element: HTMLElement,
    _positional: [],
    named: { selector?: string } = {}
  ) => {
    const selector = named.selector ?? 'thead';
    const target = element.querySelector<HTMLElement>(selector);
    if (!target) return;

    const update = () => {
      element.style.setProperty('--head-offset', `${target.offsetHeight}px`);
    };

    update();

    const observer = new ResizeObserver(update);
    observer.observe(target);
    return () => observer.disconnect();
  }
);

export default stickyOffset;
