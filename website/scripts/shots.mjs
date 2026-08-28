// og.png: rsvg-convert -w 1200 -h 630 scripts/og.svg -o public/og.png
// One-shot screenshot prep: crop status bars, resize, convert to WebP.
// Source of truth stays in docs/MyReciBook-Screenshots/ — this emits web copies.
import sharp from 'sharp'

const SRC = '../docs/MyReciBook-Screenshots'
const OUT = 'public/screenshots'

const jobs = [
  // [source, out, cropTopPx, maxWidth]
  ['Pasted Image.png', 'cookbook.webp', 0, 640],
  ['Pasted Image (Copy 4).png', 'rescue-source.webp', 48, 560], // shave OS status bar
  ['Pasted Image (Copy 5).png', 'rescue-review.webp', 0, 640],
  ['Pasted Image (Copy 7).png', 'recipe-page.webp', 0, 640],
  ['Pasted Image (Copy 2).png', 'pantry.webp', 0, 640],
  ['Pasted Image (Copy 13).png', 'handwritten.webp', 0, 760],
  ['Pasted Image (Copy 14).png', 'tiramisu.webp', 0, 640],
]

for (const [src, out, cropTop, maxW] of jobs) {
  let img = sharp(`${SRC}/${src}`)
  const meta = await img.metadata()
  if (cropTop > 0) {
    img = img.extract({ left: 0, top: cropTop, width: meta.width, height: meta.height - cropTop })
  }
  await img.resize({ width: Math.min(maxW, meta.width) }).webp({ quality: 82 }).toFile(`${OUT}/${out}`)
  console.log(out, 'done')
}
