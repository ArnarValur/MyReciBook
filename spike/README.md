# Extraction spike (T1 → Gate 1) — CLOSED

**Gate 1 passed 2026-08-06** on Arnar's own screenshots — see conductor/tracks.md
(Done). Gates were retired from context.md on 2026-08-18. Extraction has shipped
well past this spike: prompt v2 live on 0.19.0+39, proxy on Cloud Run. Everything
below is history — do not re-run it as a gate, and `out/results.md` is a stray
harness re-run from 2026-08-18, not the scoring sheet.

Throwaway validation toolkit. The app never imports anything from here.
Full plan: conductor/tracks/T1-extraction-spike/plan.md

## One-time setup (~10 min)
1. Put 10 real screenshots in `spike/screenshots/` (they stay untracked — private).
2. Free API key: aistudio.google.com → `export GEMINI_API_KEY=...`
   (or an OpenAI key → `export OPENAI_API_KEY=...`)
3. Python 3.10+, no packages needed.

## Run
    cd spike
    python3 harness.py --one screenshots/<file>.png        # smoke test, arm A
    python3 harness.py                                     # all 10, image-direct (arm A)
    python3 harness.py --mode text                         # arm B: uses <img>.txt ML Kit dumps
    python3 harness.py --provider openai --model gpt-4o-mini   # B-provider comparison

Arm B dumps come from the ocr_dump phone app — source + build steps in
`ocr_dump_main.dart` (Claude Code session on the host, S21 via USB).

## Scoring — this IS Gate 1
`out/results.md` gets one row per screenshot with auto-checks filled in.
You fill the last column: **would you cook from out/<name>.json without editing? y/n**
Gate 1 was: at least 9 of 10 "y". Passed 2026-08-06, 24 days ahead of the date we set.

## Troubleshooting
- HTTP 429: free-tier pacing — wait a minute, rerun; the harness does one image at a time.
- HTTP 400/404: model name drifted — pass a current one with --model.
- Garbage JSON: check the raw response printed on failure; usually a prompt-rule fix
  in structure_prompt.md, not code.
