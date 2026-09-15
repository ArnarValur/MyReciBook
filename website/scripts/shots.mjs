// og.png: rsvg-convert -w 1200 -h 630 scripts/og.svg -o public/og.png
// One-shot screenshot prep: crop, resize, convert to WebP.
// Sources of truth stay in conductor/docs/ — this emits the web copies.
//   conductor/docs/MyReciBook-Screenshots/          Arnar's phone, 2026-08-29 (the rescue strip)
//   conductor/docs/MyReciBook-Emulator-Shots/       tools/shoot_emulator.sh, 2026-09-09 (cards + pocket)
// Run from website/: node scripts/shots.mjs
import sharp from 'sharp'
import { existsSync } from 'node:fs'

const SRC = '../conductor/docs/MyReciBook-Screenshots'
const SRC_LIGHT = '../conductor/docs/MyReciBook Recipes Screenshots'
const EMU = '../conductor/docs/MyReciBook-Emulator-Shots'
const OUT = 'public/screenshots'

// [source, out, cropTopPx, maxWidth, cropHeightPx?]
const jobs = [
  [`${SRC}/Pasted Image (Copy 4).png`, 'rescue-source.webp', 48, 560], // shave OS status bar
  [`${SRC}/Pasted Image (Copy 5).png`, 'rescue-review.webp', 0, 640],
  [`${SRC}/Pasted Image (Copy 7).png`, 'recipe-page.webp', 0, 640],
  [`${SRC}/Pasted Image (Copy 2).png`, 'pantry.webp', 0, 640],
  [`${SRC}/Pasted Image (Copy 13).png`, 'handwritten.webp', 0, 760],
  [`${SRC}/Pasted Image (Copy 14).png`, 'tiramisu.webp', 0, 640],
  // Light-theme rescue story (peach tiramisu) — shown in light mode
  [`${SRC_LIGHT}/light-recipe1.png`, 'rescue-source-light.webp', 0, 640],
  [`${SRC_LIGHT}/light-recipe-3.png`, 'rescue-review-light.webp', 0, 640],
  [`${SRC_LIGHT}/light-recipe-4.png`, 'recipe-page-light.webp', 0, 640],
]

// Emulator set. The Pixel 7 screen is 1080×2400; the status bar ends at 130.
// Whole phones keep the status bar (they sit in a phone frame). Card windows
// crop to the part of the screen that proves the card's claim.
const windows = {
  cookmode: [830, 1440], // big step text, the timer it offers, Done
  grocery: [130, 1440], // "18 items · from 3 recipes", the Same thing? card, produce
  pantry: [340, 1440], // title, scan button, search, the dairy shelf
  diary: [340, 1440], // the day, 667 left, macros, breakfast
  product: [300, 1900], // photo, name, brand, portion, the per-100 g table
  trends: [130, 1670], // three months of bars, 78 of 87 days, the records
}
for (const theme of ['', '-dark']) {
  for (const whole of ['cookbook', 'recipe', 'import'])
    jobs.push([`${EMU}/${whole}${theme}.png`, `phone-${whole}${theme}.webp`, 0, 640])
  for (const [name, [top, height]] of Object.entries(windows))
    jobs.push([`${EMU}/${name}${theme}.png`, `card-${name}${theme}.webp`, top, 720, height])
}

for (const [src, out, cropTop, maxW, cropHeight] of jobs) {
  // Arnar's phone shots are not in the repo — skip what is not on this machine.
  if (!existsSync(src)) { console.log(out, 'skipped — no source at', src); continue }
  let img = sharp(src)
  const meta = await img.metadata()
  if (cropTop > 0 || cropHeight) {
    const height = Math.min(cropHeight ?? meta.height - cropTop, meta.height - cropTop)
    img = img.extract({ left: 0, top: cropTop, width: meta.width, height })
  }
  await img.resize({ width: Math.min(maxW, meta.width) }).webp({ quality: 82 }).toFile(`${OUT}/${out}`)
  console.log(out, 'done')
}
