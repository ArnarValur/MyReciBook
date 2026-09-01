# Translation brief — MyReciBook website (Nordic languages)

You are translating the marketing website of MyReciBook, a pay-once Android
recipe app. The voice is warm, plain and personal — a real person, not a
corporation. Recipes-in-a-card-box is the visual metaphor of the whole site.

## Your job

Translate the VALUES in these files, in place. English source of truth: `locales/en.json`.

| File | Language |
|---|---|
| `locales/nb.json` | Norwegian bokmål |
| `locales/da.json` | Danish |
| `locales/fi.json` | Finnish |
| `locales/fo.json` | Faroese |

Each file is currently a full English copy of en.json — replace every English
value with its translation, working through the file top to bottom.

## Hard rules

1. **Never change a key**, the nesting, or the key order. Values only.
2. **Do NOT touch** `en.json`, `is.json` or `sv.json` — they are human-owned.
3. Keep `{placeholder}` tokens exactly as they are (e.g. `{link}`, `{email}`, `{code}`).
4. Keep inline HTML exactly where it belongs: `<strong>…</strong>`, `<br>`.
   Translate the text inside the tags, never remove or add tags.
5. Do not translate: MyReciBook, Merkurial-Studio, Google Play, Google Drive,
   Dropbox, Gemini, Open Food Facts, support@myrecibook.com, `IMG_2041.jpg`.
6. Numbers and prices stay as written: 1,200 rescues included, 600 per top-up,
   $5, $25 (adapt the thousands separator to the language's convention, keep
   the currency in $). Never write anything implying the included rescues
   reset or refill — they don't (Decision 1, 2026-09-01).
7. Tone: informal "you" (du/þú/sinä/tú). Short sentences. No corporate
   phrasing, no legalese — the Terms page is deliberately written in plain
   speech; keep it plain in translation.
8. Some English lines are deliberately quirky chef-phrases (e.g. the stamps
   "And it's as simple as that", "So there we have it"). They are intentional —
   translate them into something equally idiomatic and warm, never flatten them
   into formal register.
9. Keep translations roughly the same length as the English where the text sits
   in UI chrome (`layout.*`, buttons like `contact.send`, tab labels) — they
   must fit on one line.
10. `layout.translationNotice` is the sticker shown on every non-English page:
    it says the page may lag behind the English original and that English
    governs. Translate it faithfully — it must keep exactly that meaning.

## Verify when done

```
node scripts/check-locales.mjs nb da fi fo
```

Must print `148/148 translated, 0 still English` for the four files and exit 0
(no MISSING / PLACEHOLDER / HTML-TAG lines). Optionally view
pages with `npm run dev` at /nb/, /da/, /fi/, /fo/.

Commit on this branch (`website-i18n`) only — never on main.
