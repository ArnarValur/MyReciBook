#!/usr/bin/env node
// Locale parity check — compares every locale file against en.json.
// For each message it verifies: same keys, same {placeholder} tokens,
// same HTML tags (<strong>, <br>, …). Exits 1 on any mismatch.
// Usage: node scripts/check-locales.mjs [locale ...]   (default: all files)
import { readFileSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const dir = join(dirname(fileURLToPath(import.meta.url)), '..', 'i18n', 'locales')
const en = JSON.parse(readFileSync(join(dir, 'en.json'), 'utf8'))

const wanted = process.argv.slice(2)
const files = readdirSync(dir).filter(f => f.endsWith('.json') && f !== 'en.json')
  .filter(f => wanted.length === 0 || wanted.includes(f.replace('.json', '')))

const flatten = (obj, prefix = '') => Object.entries(obj).flatMap(([k, v]) =>
  typeof v === 'object' && v !== null ? flatten(v, `${prefix}${k}.`) : [[`${prefix}${k}`, v]])

const tokens = s => (String(s).match(/\{\w+\}/g) ?? []).sort().join(' ')
const tags = s => (String(s).match(/<\/?\w+[^>]*>/g) ?? []).map(t => t.replace(/\s.*>/, '>')).sort().join(' ')

const enMap = new Map(flatten(en))
let bad = 0
for (const file of files) {
  const locale = file.replace('.json', '')
  const map = new Map(flatten(JSON.parse(readFileSync(join(dir, file), 'utf8'))))
  for (const [key, enVal] of enMap) {
    const val = map.get(key)
    if (val === undefined) { console.log(`${locale}: MISSING ${key}`); bad++; continue }
    if (tokens(val) !== tokens(enVal)) { console.log(`${locale}: PLACEHOLDER mismatch at ${key} — en has [${tokens(enVal)}], got [${tokens(val)}]`); bad++ }
    if (tags(val) !== tags(enVal)) { console.log(`${locale}: HTML-TAG mismatch at ${key} — en has [${tags(enVal)}], got [${tags(val)}]`); bad++ }
  }
  for (const key of map.keys())
    if (!enMap.has(key)) { console.log(`${locale}: EXTRA ${key} (not in en.json)`); bad++ }
  const untranslated = [...enMap].filter(([k, v]) => map.get(k) === v).length
  console.log(`${locale}: ${enMap.size - untranslated}/${enMap.size} translated, ${untranslated} still English`)
}
process.exit(bad ? 1 : 0)
