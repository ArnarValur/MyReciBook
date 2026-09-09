// Render a page of the site to a PNG without opening a browser — for checking
// layout from a session that has no eyes. Drives headless Chrome over DevTools
// so the colour scheme can be forced, which the plain --screenshot flag cannot.
//   node scripts/render.mjs http://localhost:3000/ out.png 1280 light
//   node scripts/render.mjs http://localhost:3000/ out.png 410 dark mobile
import { spawn } from 'node:child_process'
import { writeFileSync } from 'node:fs'
const [url, out, width, scheme, mobile] = process.argv.slice(2)
const port = 9300 + Math.floor(Math.random() * 500)
const chrome = spawn('google-chrome', ['--headless=new', '--disable-gpu', '--hide-scrollbars', `--remote-debugging-port=${port}`, '--user-data-dir=/tmp/claude-1000/chrome-shot-profile', 'about:blank'], { stdio: 'ignore' })
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
let target
for (let i = 0; i < 40 && !target; i++) { try { target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json() } catch { await sleep(250) } }
const ws = new WebSocket(target.webSocketDebuggerUrl)
await new Promise((r) => (ws.onopen = r))
let id = 0; const pending = new Map()
ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id) } }
const send = (method, params = {}) => new Promise((r) => { pending.set(++id, r); ws.send(JSON.stringify({ id, method, params })) })
await send('Page.enable')
await send('Emulation.setDeviceMetricsOverride', { width: +width, height: 900, deviceScaleFactor: 1, mobile: !!mobile })
await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: scheme }] })
await send('Page.addScriptToEvaluateOnNewDocument', { source: `try { localStorage.setItem('nuxt-color-mode', '${scheme}') } catch {}` })
await send('Page.navigate', { url })
await sleep(6000)
// scroll through so lazy images load, then back to the top
const h = (await send('Runtime.evaluate', { expression: 'document.documentElement.scrollHeight', returnByValue: true })).result.value
for (let y = 0; y < h; y += 700) { await send('Runtime.evaluate', { expression: `window.scrollTo(0, ${y})` }); await sleep(120) }
await send('Runtime.evaluate', { expression: 'window.scrollTo(0, 0)' }); await sleep(1500)
const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true, clip: { x: 0, y: 0, width: +width, height: h, scale: 1 } })
writeFileSync(out, Buffer.from(shot.data, 'base64'))
console.log('ok', out, `${width}x${h}`)
ws.close(); chrome.kill()
