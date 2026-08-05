#!/usr/bin/env python3
"""MyReciBook extraction spike harness (T1 -> Gate 1).

Zero dependencies -- Python 3.10+ stdlib only.

Usage:
  export GEMINI_API_KEY=...             # or OPENAI_API_KEY
  python3 harness.py --one screenshots/pasta.png          # smoke test
  python3 harness.py                                      # arm A: all images, image-direct
  python3 harness.py --mode text                          # arm B: <img>.txt ML Kit dumps
  python3 harness.py --provider openai --model gpt-4o-mini

Outputs: out/<name>.json per screenshot, out/results.md scorecard.
Gate 1 (conductor/context.md): >= 9 of 10 rated "would cook without editing".
"""
import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"
# Model names drift -- override with --model if these 404.
DEFAULTS = {"gemini": "gemini-3.6-flash", "openai": "gpt-4o-mini"}


def b64(path: Path) -> tuple[str, str]:
    mime = "image/png" if path.suffix.lower() == ".png" else "image/jpeg"
    return mime, base64.b64encode(path.read_bytes()).decode()


def call_gemini(key: str, model: str, prompt: str, images: list[Path]) -> str:
    parts: list[dict] = [{"text": prompt}]
    for image in images:
        mime, data = b64(image)
        parts.append({"inline_data": {"mime_type": mime, "data": data}})
    body = {
        "contents": [{"parts": parts}],
        "generationConfig": {"response_mime_type": "application/json", "temperature": 0.1},
    }
    req = urllib.request.Request(
        GEMINI_URL.format(model=model, key=key),
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        out = json.load(resp)
    return out["candidates"][0]["content"]["parts"][0]["text"]


def call_openai(key: str, model: str, prompt: str, images: list[Path]) -> str:
    content: list[dict] = [{"type": "text", "text": prompt}]
    for image in images:
        mime, data = b64(image)
        content.append({"type": "image_url", "image_url": {"url": f"data:{mime};base64,{data}"}})
    body = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "response_format": {"type": "json_object"},
        "temperature": 0.1,
    }
    req = urllib.request.Request(
        OPENAI_URL,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        out = json.load(resp)
    return out["choices"][0]["message"]["content"]


def parse_json(raw: str) -> dict:
    raw = raw.strip()
    raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw)
    return json.loads(raw)


def auto_checks(recipe: dict, schema: dict) -> list[str]:
    """Minimal structural checks -- deliberately no jsonschema dependency."""
    problems = []
    for field in schema.get("required", []):
        if field not in recipe:
            problems.append(f"missing:{field}")
    if not recipe.get("title"):
        problems.append("empty title")
    ings = recipe.get("ingredients") or []
    steps = recipe.get("steps") or []
    if len(ings) < 2:
        problems.append(f"only {len(ings)} ingredients")
    if len(steps) < 1:
        problems.append("no steps")
    for i, ing in enumerate(ings):
        if not isinstance(ing, dict) or not ing.get("raw"):
            problems.append(f"ingredients[{i}] no raw")
    for i, st in enumerate(steps):
        if not isinstance(st, dict) or not st.get("raw"):
            problems.append(f"steps[{i}] no raw")
    return problems


def main() -> None:
    ap = argparse.ArgumentParser(description="MyReciBook extraction spike harness")
    ap.add_argument("--provider", choices=["gemini", "openai"], default="gemini")
    ap.add_argument("--mode", choices=["image", "text"], default="image",
                    help="image = arm A (image-direct); text = arm B (ML Kit OCR dumps)")
    ap.add_argument("--model", default=None, help="override the default model name")
    ap.add_argument("--dir", default="screenshots")
    ap.add_argument("--one", default=None, help="run a single file")
    args = ap.parse_args()

    env = "GEMINI_API_KEY" if args.provider == "gemini" else "OPENAI_API_KEY"
    key = os.environ.get(env)
    if not key:
        sys.exit(f"Set {env} first (spike/README.md step 2).")
    model = args.model or DEFAULTS[args.provider]

    prompt_base = (ROOT / "structure_prompt.md").read_text(encoding="utf-8")
    schema = json.loads((ROOT / "recipe.schema.json").read_text(encoding="utf-8"))

    if args.one:
        images = [Path(args.one)]
    else:
        src = (ROOT / args.dir) if not Path(args.dir).is_absolute() else Path(args.dir)
        images = sorted(p for p in src.glob("*") if p.suffix.lower() in (".png", ".jpg", ".jpeg"))
    if not images:
        sys.exit(f"No screenshots found in {args.dir}/ (README step 1).")

    # Multi-screenshot recipes: name-1.png + name-2.png share the recipe "name".
    groups: dict[str, list[Path]] = {}
    for img in images:
        base = re.sub(r"[-_]\d+$", "", img.stem)
        groups.setdefault(base, []).append(img)

    outdir = ROOT / "out"
    outdir.mkdir(exist_ok=True)
    call = call_gemini if args.provider == "gemini" else call_openai
    rows = []

    for base, imgs in groups.items():
        label = base if len(imgs) == 1 else f"{base} ({len(imgs)} imgs)"
        prompt = prompt_base
        if len(imgs) > 1:
            prompt += ("\n\nNOTE: the images are consecutive screenshots of ONE recipe, "
                       "in order. Combine them into a single recipe.")
        prompt += "\n\nTARGET JSON SCHEMA:\n" + json.dumps(schema, indent=1)
        image_arg = imgs
        if args.mode == "text":
            dumps = []
            for img in imgs:
                dump = img.parent / (img.name + ".txt")
                if not dump.exists():
                    print(f"SKIP  {img.name}: no OCR dump {dump.name} (build ocr_dump first)")
                    dumps = None
                    break
                dumps.append(dump.read_text(encoding="utf-8"))
            if dumps is None:
                continue
            prompt += "\n\nOCR TEXT (on-device ML Kit):\n" + "\n\n--- next screenshot ---\n\n".join(dumps)
            image_arg = []

        t0 = time.time()
        try:
            raw = call(key, model, prompt, image_arg)
            recipe = parse_json(raw)
            # The LLM invents these — stamp ground truth ourselves.
            recipe.setdefault("extraction", {})
            recipe["extraction"].update({
                "model": model, "mode": "image" if args.mode == "image" else "ocr_text",
                "extracted_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            })
            problems = auto_checks(recipe, schema)
        except urllib.error.HTTPError as e:
            print(f"FAIL  {label}: HTTP {e.code} {e.read()[:300]!r}")
            continue
        except Exception as e:  # noqa: BLE001 -- spike tool, show everything
            print(f"FAIL  {label}: {type(e).__name__}: {e}")
            continue

        dt = time.time() - t0
        (outdir / f"{base}.json").write_text(
            json.dumps(recipe, indent=2, ensure_ascii=False), encoding="utf-8")
        status = "auto-OK" if not problems else "; ".join(problems)
        rows.append((label, f"{dt:.1f}s", status))
        print(f"OK    {label:35} {dt:5.1f}s  {status}")

    stamp = time.strftime("%Y-%m-%d %H:%M")
    md = [
        f"# Spike results — {stamp}",
        f"provider={args.provider} · model={model} · mode={args.mode}",
        "",
        "| screenshot | latency | auto-checks | would cook without editing? (y/n) |",
        "|---|---|---|---|",
    ]
    md += [f"| {n} | {d} | {s} |  |" for n, d, s in rows]
    md += ["", "Gate 1 = at least 9 of 10 'y' (conductor/context.md).",
           "Read each out/<name>.json next to its screenshot, then fill the last column."]
    (outdir / "results.md").write_text("\n".join(md), encoding="utf-8")
    print(f"\n{len(rows)} extracted → out/ · scorecard: out/results.md — fill the y/n column.")


if __name__ == "__main__":
    main()
