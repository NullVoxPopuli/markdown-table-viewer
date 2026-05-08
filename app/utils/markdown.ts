import { parseInline } from 'marked';

export function convertMarkdown(str: string | undefined): string {
  return parseInline(str ?? '', { gfm: true }) as string;
}
