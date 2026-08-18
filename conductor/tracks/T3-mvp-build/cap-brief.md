# Cap brief — set the fair-use number from evidence, not vibes
*2026-08-18, Cowork research session. Feeds: D7 counter · D10 listing copy ·
proxy `FREE_MONTHLY_CAP`. Build work goes to a Code session.*

## Why
Constraint 2: the listing states a fair-use AI cap from day one. The current
100/mo is a strawman with zero measurements behind it.

## What the research already settled (sources at bottom)
- Model: `gemini-3.6-flash` (proxy allowlist). Official price **$0.75/M in,
  $3.75/M out through 2026-12-31 — DOUBLES 2027-01-01** to $1.50/$7.50.
  Launch is 11 Dec: the intro price survives three weeks. All cap math at
  the 2027 price, or the cap costs 2× forever.
- Output price **includes thinking tokens** — an invisible multiplier we have
  never measured.
- Unmeasured estimate: screenshot ≈1.0–1.6K tokens in + ~0.4K prompt,
  recipe JSON ≈1–1.5K out → ~1.5¢/extraction at 2027 prices, **1–5¢** once
  thinking is counted. At cap 100/mo a maxed user costs $1–5/mo against
  ~$21 net per $25 sale. Economics hold if the thinking guess holds.
- Shape worry: "rescue your camera roll" is front-loaded. If a real roll
  holds 300 recipe screenshots, a flat 100/mo makes the core promise take
  three months. Candidate shape: one-time rescue allowance + smaller
  monthly trickle. Arnar decides — with data.

## Build task (Code session, ~30–45 min)
1. Log `usageMetadata` per extraction: promptTokenCount,
   candidatesTokenCount, thoughtsTokenCount, model, timestamp — **counts
   only, never request bodies** (constraint 3). Capture at BOTH points:
   the proxy relay and the direct-key dev-mode client (dev mode is what
   actually runs today — jsonl in the app-support dir, adb pull).
2. `spikes/cap_math` script: jsonl → median/p90 in/out/thinking, cost per
   extraction at intro + 2027 prices, projected monthly cost at caps
   {50, 100, 200} and a 300-screenshot rescue.
3. Logging must never block or fail a response (proxy_test cover).

## Research still open
- `thinkingConfig` on 3.6-flash: can thinking be capped/off for this
  structured task? Likely the single biggest cost lever. (docs check)
- Free-tier RPD for 3.6-flash — does the closed track ride $0 until the
  proxy deploys?
- Billing guardrails on gen-lang-client-0166122901: daily quota cap +
  budget alert (Arnar, console, ~15 min — already in pulse queue).
- Camera-roll census: Arnar counts his own recipe screenshots; one message
  to the 12 testers asking theirs. Sets the rescue-allowance number.
- Retry / add-screenshot rate — the log captures it free (requests vs
  recipes saved). It multiplies every estimate.
- Competitor fair-use wording (Crouton, ReciMe listings) → D10 copy.

## Decision that returns to Arnar
Cap shape + the listed number (flat monthly vs rescue+monthly), after
~2 weeks of logged real usage. Lands beside D10 pricing in T4.

Sources: ai.google.dev/gemini-api/docs/pricing (official, fetched
2026-08-18) · clawrouters.com/blog/cheapest-vision-multimodal-llm-api-2026
· cloudzero.com/blog/llm-api-pricing-comparison.
