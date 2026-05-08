import { parseInline } from 'marked';

/** Render an inline-only markdown fragment with GFM enabled. */
export function convertMarkdown(str: string | undefined): string {
  return parseInline(str ?? '', { gfm: true }) as string;
}
