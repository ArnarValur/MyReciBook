# MyReciBook website

Card-box landing — the "Website Card Box" design canvas as a Nuxt 4 site.

## Map
- `app/layouts/default.vue` — the box: kraft background, lid header, footer
- `app/pages/` — index (the landing), privacy, terms, contact (drafts stamped)
- `app/error.vue` — the 404 card
- `app/assets/css/main.css` — fonts, Nuxt UI theme, card-box tokens
- `app/assets/css/cardbox.css` — shared paper primitives (paper, ruled, cta…)
- `app/components/` — LogoMark, CardTape, PhoneMockup (`src` = real screenshot)
- `public/screenshots/` — WebP copies; sources live in docs/MyReciBook-Screenshots/
- `copy-notes.md` — copy audit: what's fixed, what's flagged for Arnar

## Commands
- `pnpm dev` — local dev
- `pnpm generate` — static build to `.output/public` (SEO: sitemap, robots, JSON-LD)
- `node scripts/shots.mjs` — re-derive WebP screenshots from docs/
- `rsvg-convert -w 1200 -h 630 scripts/og.svg -o public/og.png` — the OG card
- `./deploy-staging.sh` — Cloud Run staging on MyReciBook-Dev (NOT run yet)
