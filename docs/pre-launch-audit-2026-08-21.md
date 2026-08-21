# Pre-launch audit — MyReciBook 0.10.0+8
**Date:** 2026-08-21 · **Scope:** `app/lib` (86 files, 22.8k lines), `app/android`, `proxy/`
**Method:** full read of the security surface; two findings verified by running code, the rest by reading. Verification status is marked on every item.

> **Status update, same day.** B1, B2, H1, H2\*, H3 and M3 are fixed on branch
> `harden/pre-launch-bake` (0.10.1+8). B3 and M1, M2, M4–M6 are untouched.
> \*H2 partially: tokens are still plaintext — see its section.
> The proxy changes are code-complete but **have never been deployed**.

---

## TL;DR

The Dart and Kotlin code is genuinely good — OAuth is textbook PKCE, the SAF bridge is careful,
`flutter analyze` is clean, hostile-share paths already no-op instead of crashing.

**The risk is not in the app. It is in the proxy and the paperwork.**
Three things block taking money. One confirmed crash and one blind spot follow close behind.

---

## BLOCKERS — fix before the listing goes live

### B1. ~~The extraction proxy has no authentication~~ — FIXED (not deployed)
`proxy/lib/proxy.dart` — the only gate is the `X-Install-Id` header, which the *client* mints
(`app/lib/data/install_id.dart`, a plain `Uuid().v4()`). Nothing proves the caller is your app.

The proxy URL ships compiled into the APK via `--dart-define EXTRACTION_PROXY_URL`. `strings` on
the extracted `libapp.so` finds it in seconds. From there anyone writes a loop that sends a fresh
UUID per request and gets **unmetered Gemini on your card**. There is no per-IP limit, no shared
secret, and no global ceiling.

> This is the single largest exposure in the project. It converts a fixed $24.99 sale into an
> open-ended liability.

**Fix:** Play Integrity API (or Firebase App Check) attestation on every request — the standard
answer for exactly this. Plus, independently: a hard global daily spend ceiling in the proxy and a
GCP billing alert, so a bypass costs you a bounded amount rather than an unbounded one.
*Status: read-only. The bypass is straightforward from the code; I did not run it against a live deploy.*

### B2. ~~The advertised fair-use cap cannot be enforced~~ — FIXED (not deployed)
`proxy/lib/usage_counter.dart` — `InMemoryUsageCounter` holds counts in a plain `Map` in process
memory. Cloud Run scales to zero and scales out horizontally, so counts evaporate on cold start and
split across instances. The file's own comment says this is "honest for the closed track".

It is not honest for a paid listing. **600/yr is a promise in the store copy that the code cannot
keep** — it under-counts in every direction at once.

**Fix:** move the counter behind Firestore or Redis (the `UsageCounter` interface is already the
seam — this is a small change). Do it together with B1; either alone leaves the hole open.
*Status: read-only, but the behaviour follows directly from Cloud Run's execution model.*

### B3. No privacy policy, no Data Safety declaration
Nothing in the repo. Play refuses submission without a privacy policy URL, and the Data Safety form
must declare every one of these — all of which the code actually does today:

| What leaves the device | Where to | Code |
|---|---|---|
| Recipe screenshots (photos) | Google Gemini | `data/gemini_extractor.dart` |
| Shared URLs + full page text | the recipe site, then Gemini | `data/link_extractor.dart` |
| Scanned barcodes | Open Food Facts | `data/off_client.dart` |
| Recipe files, pantry, diary | Google Drive / Dropbox | `data/remote_store.dart` |
| Anonymous install id | your proxy | `data/install_id.dart` |

The app's actual privacy posture is strong — local-first, no account, no telemetry, `drive.file`
scope only. That is a selling point. It just has to be written down.
*Status: confirmed absent — searched the repo.*

---

## HIGH

### H1. ~~All async crashes are swallowed~~ — FIXED
`app/lib/main.dart:100` — `PlatformDispatcher.instance.onError` returns `true`. Every uncaught async
error is logged to the local ring buffer and suppressed. The comment is eyes-open about it and says
"revisit for production if vitals ever matter."

They matter now. Once you are selling, the local log only reaches you if a user finds the
long-press door on the Settings version footer and emails you the paste. Play Console vitals will
show a suspiciously perfect app right up until the reviews explain why it is not.

**Fix:** keep the local log, but let a chosen subset rethrow so vitals sees it — or add a crash
reporter. That is a D8 policy decision (telemetry was ruled out), so it is your call, not mine.
*Status: confirmed by reading; behaviour is explicit in the code.*

### H2. OAuth refresh tokens stored in plaintext
`app/lib/data/token_store.dart` writes `app-support/tokens.json` as plain JSON. Cloud backup and
device-transfer are correctly excluded (`res/xml/*.xml` — good, and easy to miss), so this is not
exposed to Google's backup. But on a rooted device, or via any ADB-backup-capable path, the Drive
and Dropbox refresh tokens read straight out.

The file's own comment already names the fix: "production hardening: consider
EncryptedSharedPreferences."

**Fix:** `flutter_secure_storage` — Android Keystore-backed, drop-in for this store's tiny surface.
*Status: confirmed by reading.*

### H3. ~~CONFIRMED CRASH — a malformed HTML entity kills link import~~ — FIXED
`app/lib/data/link_extractor.dart` — `_decodeEntities` calls `String.fromCharCode(code)` on a value
parsed straight out of page content, with no range check. Anything above `0x10FFFF` throws.

I wrote a throwaway test against the real function and ran it:

```
&#x110000;     → RangeError: Invalid value: Not in inclusive range 0..1114111: 1114112
&#99999999999; → RangeError: Invalid value: Not in inclusive range 0..1114111: 99999999999
```

`RangeError` is an `Error`, not an `Exception`, so `extractContent`'s carefully typed catch ladder
(`SocketException` / `TimeoutException` / `ClientException` / `IOException`) does not catch it. It
escapes into the import flow. A single CMS that emits a bad numeric entity breaks that site's
import permanently, and reads to the user as the app being broken.

**Fix:** range-guard the branch — return the original match when the code point is out of range or
in the surrogate block. Roughly three lines.
*Status: **verified by execution.** Test written, run, failed as described, then deleted.*

---

## MEDIUM

### M1. Redirects are followed with no scheme or host allowlist (SSRF)
`android/.../NetBridge.kt` — `url = URL(url, loc)` takes the `Location` header verbatim, up to 5
hops. The starting URL is constrained to `http(s)` by ShareBridge's regex, but **the redirect target
is not constrained at all**, and the fetched body flows onward to Gemini and to the review screen.

A hostile shared link can therefore redirect into `localhost` or the user's LAN, and the response
comes back. Two things limit the damage: non-`HttpURLConnection` schemes (`file:`, `jar:`) die on
the cast, and cleartext is blocked by default at targetSdk 28+, so plain `http://` internal hosts
fail. Private hosts reachable over https still resolve.

Separately, request headers are re-applied on every hop — fine today (User-Agent only), a leak the
moment anything authenticated is ever added.

**Fix:** allowlist `https` on redirect targets, reject private/loopback address ranges, and drop
headers on cross-host hops.
*Status: read-only.*

### M2. Cache directories are never pruned
`ShareBridge.copyToCache` writes every shared image to `cacheDir/shared`, and `CoverFetcher` writes
every downloaded cover to `cache/link_covers`. Nothing in the app ever deletes either. Android only
clears them under storage pressure. A heavy importer accumulates hundreds of MB, and "the recipe app
is eating my storage" is a one-star review.
*Status: confirmed — grepped every delete path in `lib/`; neither directory appears.*

### M3. ~~A failed upstream still burns the user's quota~~ — FIXED
`proxy/lib/proxy.dart` — `usage.increment(installId)` runs *before* the Gemini call, and is never
rolled back when the call returns 502 or times out. The user pays a fair-use credit for your
outage.
*Status: confirmed by reading.*

### M4. ANR risk — one isolate does almost everything
`compute()` appears exactly once in the codebase (cover resizing). Regex-parsing up to 10 MB of
HTML, JSON-LD walking, PDF generation and full recipe-store scans all run on the main isolate.
Play Console tracks ANR rate and it feeds store ranking.
*Status: confirmed — grepped `compute(` / `Isolate.` across `lib/`.*

### M5. `targetSdk` / `minSdk` are inherited, not pinned
`android/app/build.gradle.kts` uses `flutter.targetSdkVersion`. Correct today on Flutter 3.44, but a
toolchain bump silently moves your Play compliance level with no diff in your repo. Pin them
explicitly.

### M6. Release builds do not shrink or obfuscate
No `isMinifyEnabled` / `isShrinkResources` in the `release` block. Dart is AOT-compiled so the
payoff is smaller than on a native Android app, but the Kotlin bridges and plugin code ship
readable, and that includes the shape of the proxy call.

---

## LOW

- **L1.** The custom-scheme OAuth redirect can be registered by a co-installed app. PKCE means a
  stolen code is not redeemable, so this is defence-in-depth only. Chrome Custom Tabs + App Links
  would close it.
- **L2.** `ogImageFromHtml` accepts any URL matching `startsWith('http')` — `httpfoo://` passes.
  `imageUrlFromJsonLd` next to it does the check properly.
- **L3.** `main.dart:97` `debugPrint`s raw error + stack to logcat. `CrashLog` redacts `key=…`, this
  path does not.
- **L4.** Per-install caps still multiply by install count. A global ceiling is the only actual
  bound on spend.

---

## What is already right

Worth saying plainly, because it is unusual:

- **OAuth** — authorization-code + PKCE S256, `Random.secure()`, state verified, every exit typed,
  no client secret in the APK. Textbook.
- **`AuthBridge.launchUrl`** refuses non-https. **`ShareBridge.guessExtension`** strips path
  separators out of a sender-controlled filename. **`SafBridge`** distinguishes a dead grant from an
  IO failure so it can re-pick instead of crashing.
- **Backup rules** exclude tokens and the crash log from cloud backup *and* device transfer, on both
  the API ≤30 and API 31+ paths. Very commonly missed.
- **`writeStringAtomic`** — one tmp+rename discipline, serialized per path, after five hand-rolled
  copies had drifted.
- **The proxy's design** is right even though its enforcement is not: allowlisted model, bounded
  body counted as it streams rather than trusting Content-Length, no upstream error passthrough
  (which could carry the key), bodies never logged.
- `flutter analyze` — 1 warning, an unused import in a test.
- 61 test files against 86 source files.

---

## What changed on 2026-08-21

| Finding | State | Where |
|---|---|---|
| B1 App Check | Verified server-side behind `APP_CHECK_ENFORCE`, fails closed. App sends the token. **Not yet enforced** — needs a build with google-services.json on the internal track. | `proxy/lib/app_check.dart`, `app/lib/data/app_check.dart` |
| B2 Durable ledger | Firestore, one doc per bucket, atomic reserve, lazy anniversary reset. Proxy refuses to boot if Firestore is unreachable. | `proxy/lib/firestore_ledger.dart` |
| B3 Privacy policy | **Untouched.** Still blocks submission. | — |
| H1 Swallowed crashes | `onError` returns false; reporter records locally always, uploads on consent, scrubs recipe text. | `app/lib/data/crash_reporter.dart` |
| H2 Plaintext tokens | **Untouched.** Still `app-support/tokens.json` in the clear. | — |
| H3 Entity crash | Invalid code points → U+FFFD. Regression test added. | `app/lib/data/link_extractor.dart` |
| M3 Quota on failure | Refunded on timeout, unreachable, and any upstream ≥400. | `proxy/lib/proxy.dart` |
| — | Rate limit 10/min AND 50/day per bucket, global breaker 2000/day. The daily governor came from Arnar's catch: the two-week free window was drainable. | `proxy/lib/usage_counter.dart` |

Still open and unhardened: **M1** redirect SSRF, **M2** cache pruning,
**M4** ANR/isolates, **M5** pinned targetSdk, **M6** R8, and all of **L1–L4**.

## Suggested order

1. **B1 + B2 together** — proxy attestation and a durable counter. Same deploy, and neither works alone.
2. **B3** — privacy policy and Data Safety. Blocks submission; needs no code.
3. **H3** — the confirmed crash. Three lines.
4. **H1, H2** — crash visibility and Keystore for tokens.
5. **M1–M6** — hardening pass.
