# table-viewer

General table viewer for parsing tables on public Markdown documents to interact with, sort, and filter.
All powered by query params.

```
https://markdown-table.nullvoxpopuli.com
  ?file=url-to-file&key=where-table-starts
```

## Examples

From [disk perf](https://github.com/NullVoxPopuli/disk-perf-git-and-pnpm),

- [this table compares disk performance](<https://markdown-table.nullvoxpopuli.com/?file=https%3A%2F%2Fraw.githubusercontent.com%2FNullVoxPopuli%2Fdisk-perf-git-and-pnpm%2Frefs%2Fheads%2Fmain%2FREADME.md&key=&cv=[[%22%20Clean%20(s)%20%22%2C%22%2300aa00%22%2C%22%23aa0000%22],[%22%20Install%20(s)%20%22%2C%22%2300aa00%22%2C%22%23aa0000%22]]>)
- [this table is a ranked playlist, also sortable by release year](https://markdown-table.nullvoxpopuli.com/?cv=%5B%5B%22Released%22%2C%22%23ff2600%22%2C%22%23008e00%22%5D%2C%5B%22Rank%22%2C%22%23008e00%22%2C%22%23ff2600%22%5D%5D&file=https%3A%2F%2Fraw.githubusercontent.com%2Fdnk8n%2Fawesome-vibe-coded-playlists%2Frefs%2Fheads%2Fmain%2Fplaylists%2Fjersey-sound-top-100%2Fjersey-sound-top-100.md&key=&prefs=%7B%22plugins%22%3A%7B%22e%22%3A%7B%22table%22%3A%7B%7D%2C%22columns%22%3A%7B%22Track%22%3A%7B%22isVisible%22%3Atrue%7D%7D%7D%7D%7D)
