# Tags rethink — canvas sources (2026-09-03)

Live canvas: https://claude.ai/code/artifact/0cdac4b7-4d69-41db-a56a-9c6262ca31db

Direction A was chosen by Arnar the same day and built. The artboards here
are the working files behind that canvas: `gen.mjs` writes the six
`*.dc.html` artboards and `canvas.json`. Regenerate with `node gen.mjs`.

- Main — the cookbook: one grid, tag tiles above it.
- Filtered — a tag selected: chip + count + "Edit tag" on the header.
- TagSheet — the one editor, a bottom sheet.
- Review — rescue review with the site's tags as suggestions.
- RailOption, ContentsOption — the two low-fi alternatives, not chosen.
