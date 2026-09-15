// Play listing screenshots + welcome-slide crops, from the emulator set.
//
// Input : the 1080×2400 Pixel 7 shots tools/shoot_emulator.sh writes.
// Output: <out>/play/light|dark/NN-name.png  1080×1920 store frames
//         <tiles>/{rescue,cookmode,grocery}[-dark].webp  welcome-slide tiles (app assets)
//
// A store frame is a cream (or navy) card: a headline in Plus Jakarta Sans,
// one Inter line under it, and the phone screen bleeding off the bottom
// with the brand's blue-tinted shadow. Play wants 16:9…9:16 and each side
// 320–3840 px, which a raw 1080×2400 (2.22:1) shot is not.
//
// Run: node tools/play_shots.mjs [shots-dir] [out-dir] [tiles-dir]
import { mkdirSync } from 'node:fs'
import { createRequire } from 'node:module'
const sharp = createRequire(import.meta.url)('../website/node_modules/sharp')

const [SRC = 'conductor/docs/MyReciBook-Emulator-Shots', OUT = 'conductor/docs/play-listing', TILES = 'app/assets/onboarding'] = process.argv.slice(2)

const W = 1080, H = 1920
const themes = {
  light: { suffix: '', bg: '#FAF8F0', head: '#24389C', sub: '#454652', border: 'rgba(197,197,212,0.5)', shadow: 'rgba(36,56,156,0.18)' },
  dark:  { suffix: '-dark', bg: '#0F1117', head: '#BAC3FF', sub: '#C5C5D4', border: 'rgba(69,70,82,0.9)', shadow: 'rgba(0,0,0,0.5)' },
}

// [shot, headline lines, sub line]. Sentence case; the house verb is rescue.
const frames = [
  ['import',   ['Rescue recipes from', 'your camera roll'],   'Share a screenshot, paste a link, or snap a card.'],
  ['recipe',   ['Filed properly,', 'every time'],             'Ingredients, steps and timings — reviewed by you.'],
  ['cookbook', ['A cookbook you', 'actually own'],            'Plain files on your phone. No account. No subscription.'],
  ['cookmode', ['Cook mode for', 'floury thumbs'],            'One big step at a time. The screen stays awake.'],
  ['grocery',  ['A grocery list from', 'any recipe'],         'One tap adds it. Quantities merge across recipes.'],
  ['diary',    ['A food diary', 'that adds up'],              'Log a day in seconds and see what is left.'],
  ['pantry',   ['Your pantry,', 'on a shelf'],                'Scan a barcode and the nutrition fills itself in.'],
  ['trends',   ['Three months', 'at a glance'],               'Averages, streaks and records from your own days.'],
]

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;')

async function frame(theme, [shot, head, sub], n) {
  const t = themes[theme]
  const phoneW = 880, phoneH = Math.round(phoneW * 2400 / 1080), px = (W - phoneW) / 2, py = 470, r = 48
  const phone = await sharp(`${SRC}/${shot}${t.suffix}.png`).resize(phoneW, phoneH).png().toBuffer()
  const mask = Buffer.from(`<svg width="${phoneW}" height="${phoneH}"><rect width="${phoneW}" height="${phoneH}" rx="${r}" fill="#fff"/></svg>`)
  // Round the corners, then keep only what fits above the bottom edge.
  // (two pipelines: sharp runs extract before composite whatever the call order)
  const masked = await sharp(phone).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer()
  const rounded = await sharp(masked).extract({ left: 0, top: 0, width: phoneW, height: H - py }).png().toBuffer()
  const svg = `<svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">
    <defs><filter id="s" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="28"/></filter></defs>
    <rect width="${W}" height="${H}" fill="${t.bg}"/>
    <rect x="${px}" y="${py + 24}" width="${phoneW}" height="${H}" rx="${r}" fill="${t.shadow}" filter="url(#s)"/>
    <g font-family="Plus Jakarta Sans" font-weight="800" font-size="76" fill="${t.head}" letter-spacing="-1.5">
      ${head.map((l, i) => `<text x="80" y="${190 + i * 88}">${esc(l)}</text>`).join('')}
    </g>
    <text x="80" y="${190 + head.length * 88 + 26}" font-family="Inter" font-size="32" fill="${t.sub}">${esc(sub)}</text>
    <rect x="${px - 1}" y="${py - 1}" width="${phoneW + 2}" height="${H}" rx="${r + 1}" fill="none" stroke="${t.border}" stroke-width="2"/>
  </svg>`
  const out = `${OUT}/play/${theme}/${String(n + 1).padStart(2, '0')}-${shot}.png`
  await sharp(Buffer.from(svg)).composite([{ input: rounded, left: px, top: py }]).png().toFile(out)
  return out
}

// Welcome slide tiles. The tile is (screen − 40) wide and 220 or 420 tall;
// the crop keeps that ratio at full width so BoxFit.cover has nothing to cut.
// [shot, top, tile height]
const tiles = [
  ['import', 1010, 220],   // "Add to your book" + the screenshots and link rows
  ['cookmode', 780, 220],  // the big step text
  ['grocery', 130, 420],   // title, the count line, produce, pantry
]
async function tile([shot, top, h], suffix) {
  const cropH = Math.round(1080 * h / 320)
  const out = `${TILES}/${shot === 'import' ? 'rescue' : shot}${suffix}.webp`
  await sharp(`${SRC}/${shot}${suffix}.png`).extract({ left: 0, top, width: 1080, height: cropH })
    .resize(800).webp({ quality: 88 }).toFile(out)
  return out
}

for (const th of Object.keys(themes)) mkdirSync(`${OUT}/play/${th}`, { recursive: true })
mkdirSync(TILES, { recursive: true })
for (const th of Object.keys(themes)) for (const [i, f] of frames.entries()) console.log(await frame(th, f, i))
for (const th of Object.values(themes)) for (const t of tiles) console.log(await tile(t, th.suffix))
