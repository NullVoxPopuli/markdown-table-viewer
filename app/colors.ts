import { interpolate } from 'culori';
import type QPService from './services/qp.ts';

/**
 * Factory functino for a given dataset which returns a single function
 * for getting the color of a value at a particular range.
 * (If configured via query params)
 */
export function colors(
  qp: QPService,
  data: { headers: string[]; rows: string[][] }
) {
  const { headers, rows } = data;

  const maxCache: Record<number, number> = {};
  const minCache: Record<number, number> = {};
  const interpolationCache: Record<
    number,
    ReturnType<typeof interpolate<'oklch'>>
  > = {};

  function maxOf(hIndex: number) {
    if (maxCache[hIndex]) return maxCache[hIndex];

    const values = rows
      .map((row) => row[hIndex])
      .map((x) => parseFloat(x!))
      .filter((x) => !isNaN(x));

    return Math.max(...values);
  }

  function minOf(hIndex: number) {
    if (minCache[hIndex]) return minCache[hIndex];

    const values = rows
      .map((row) => row[hIndex])
      .map((x) => parseFloat(x!))
      .filter((x) => !isNaN(x));
    return Math.min(...values);
  }

  function getInterpolation(hIndex: number, end: string, start: string) {
    if (interpolationCache[hIndex]) return interpolationCache[hIndex];

    const interpolation = interpolate([end, start], 'oklch');

    interpolationCache[hIndex] = interpolation;

    return interpolation;
  }

  return {
    for(hIndex: number, value: string) {
      if (!value) return;
      const heading = headers[hIndex];
      if (!heading) return;
      const num = parseFloat(value);

      if (isNaN(num)) return;

      const validation = qp.cv?.find((v) => v[0] === heading);
      if (!validation) return;

      const interpolation = getInterpolation(
        hIndex,
        validation[1],
        validation[2]
      );

      const max = maxOf(hIndex);
      const min = minOf(hIndex);
      const normalized = (num - min) / (max - min);
      const color = interpolation(normalized);

      return `oklch(${color.l} ${color.c} ${color.h}deg)`;
    },
  };
}
