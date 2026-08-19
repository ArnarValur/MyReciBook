# AI cap mechanics — measuring, showing, controlling, and selling more

Researched and written 2026-08-19. Answers five questions from Arnar: how do we
measure each user's AI use, how do they see what's left, how do we control usage,
how does the GCP/API-key setup work in production, and how do users top up when
the cap runs out. Inputs: three deep research passes (Play Billing, GCP/Gemini,
cap UX + sentiment), all source-linked at the bottom; all arithmetic verified by
script. This doc is the design for the parked "durable cap store" and half of the
open billing seam.

---

## 0 · The economics first — verified numbers that make everything else calm

Per rescue on gemini-3.5-flash-lite (current safe-to-plan pricing, $0.30/M input,
$2.50/M output, thinking set to minimum):

| Path | Cost per rescue |
|---|---|
| Screenshot (on-device OCR text → structure) | ~$0.0026 |
| Raw image fallback (handwriting etc.) | ~$0.0024 |
| Webpage text fallback (no JSON-LD) | ~$0.0056 |
| Blended (70/10/20 mix) | **~$0.0032 — a third of a cent** |

- A user who maxes all 600 rescues costs **~$1.91/year** ($3.36 if every one were
  a webpage fallback). One $24.99 sale nets ~$21.24 after Play's 15% — that
  covers **11 years of a maxed-out user**, ~44 years of a realistic one (150/yr).
- Fleet: 1,000 active importers ≈ $41/mo; 5,000 ≈ $207/mo — against ~$106K gross
  from those 5,000 sales. Hosting and the counter are ~$0 (free tiers cover both).
- JSON-LD link imports and typed recipes cost us nothing and never count.

**Consequence:** the cap is not margin protection — the margin barely notices.
The cap exists to (a) block abuse (one leaked endpoint or one scripted user could
burn real money), and (b) keep the promise honest — a stated number instead of
the "unlimited (fair use applies)" asterisk everyone else hides behind. 600/year
is 50/month, 11.5/week, 1.6/day — more than double ReciMe's *free-tier* gate
(~5/week) and above any measured home-cook saving rate we found. The number is
generous and can stay.

## 1 · How we measure what each user uses

Plain words first: when someone buys the unlock, Google hands the app a receipt
string — the **purchase token**. The same token comes back on every reinstall
and on every device signed into that Google account (`queryPurchasesAsync`).
Google's own docs bless it as a database primary key. That receipt is the quota
bucket. No account, no email, no name — the proxy stores a **hash** of it.

The flow:

1. App launch → `queryPurchasesAsync` → unlock's purchase token.
2. First contact with the proxy: proxy verifies the token against Google
   (`purchases.productsv2.getproductpurchasev2`), **acknowledges it server-side**
   (unacknowledged purchases auto-refund after 3 days — silent lost sale),
   creates one Firestore row keyed to the token hash, and returns a short-lived
   signed pass (JWT) so we don't re-verify every call.
3. Every AI call carries the pass. Proxy checks the counter, calls Gemini,
   increments (`FieldValue.increment` inside the cap-check transaction), and
   returns `{used, cap, resets_at}` in every response.
4. A daily job polls Google's **Voided Purchases API**: refunded unlock → token
   dead (403); refunded top-up → negative balance. This closes the
   buy-register-refund-keep-using hole.

What counts as **1 rescue**: one recipe structured by the AI. A five-screenshot
recipe stitched into one is 1 rescue. A failed extraction is 0 — the proxy
refunds the count; failures never spend the user's allowance. Link imports that
read JSON-LD are 0. Typing is 0, forever.

**Decided 2026-08-19 — the counter is per-purchase** (agreed with Arnar;
constraint 3 in `conductor/context.md` updated). The rationale, kept for the
record: per-install was broken both ways — reinstalling reset the cap (free
unlimited AI via clearing app data), and a user with a phone + tablet got
punished with two half-caps. Per-purchase is strictly better and equally
anonymous.

Before billing exists (closed test): count per install ID; license-tester
purchases arrive flagged `purchaseType: Test` and get a separate ledger. The
closed test's real proxy traffic is also our first fair-use measurement — it
answers "nothing measured yet" before the cap number is printed anywhere.

Privacy story stays intact: the proxy stores token hash, counter, timestamps —
never recipe content (constraint already), and the counting is disclosed on the
paywall card. "No telemetry" remains true; a quota is not analytics.

**The counter document, precisely** (expanded 2026-08-19 on Arnar's question).
One Firestore document per buyer at `quota/{sha256(purchaseToken)}`:

```
status:       active        # flips to "voided" on a Play refund → 403
cap:          600
used:         143           # spent from this year's allowance
resetsAt:     <purchase anniversary>   # lazy reset — no cron
graceUntil:   <purchaseTimeMillis + 14 days>  # from Google's record,
                                              # so reinstalls can't stretch it
graceUsed:    27            # grace spending, quiet ceiling 300, then falls
                            # through to normal counting (never a hard stop)
topupBalance: 0             # bought packs, never expire
test:         false         # license-tester purchases, separate ledger
```

Request flow: one atomic transaction walks the ladder — grace window → included
allowance → top-up balance → gentle stop — and reserves the slot **before**
Gemini is called, so parallel queue items can't overshoot a nearly-empty cap.
If Gemini fails, a second transaction refunds whichever bucket was charged
(that's how "failures never count" is kept). Spending order is deliberate:
the expiring included allowance burns first, never-expiring paid top-ups last —
a user never loses paid credit while free allowance sat unused. The anniversary
reset is lazy: each request checks `now > resetsAt`, zeroes `used` and advances
the date — no scheduled job; the voided-purchases cron stays the only cron.
Cost: one read + one write per rescue (plus one write on a failure refund) —
inside Firestore's free tier at every reachable scale. Every response returns
`{used, cap, graceUntil, topupBalance, resetsAt}` so the app's counter UI is
always current with zero extra calls.

## 2 · How users see what's left

- A quiet, permanent counter where the decision happens — the import sheet and
  the paywall, not buried in settings: **"487 of 600 rescues left — resets 12
  March."** The proxy returns the balance in every response; the app caches it;
  zero extra network calls.
- One line on the import sheet before an AI path: "Uses 1 of your 600."
- Exactly two proactive nudges: at ~80% ("480 of 600 used — plenty left, just so
  you know") and at exhaustion. The exhausted state offers the free paths first
  — "Type it in (always free)" — and the top-up second. A user must **never**
  discover the cap through a failed extraction; that pattern (Adobe's expiring
  credits, Figma's opaque burn) is where the documented rage lives.
- The cap statement at purchase stays in writing, as already promised.

## 3 · How we control usage — eight layers, cheapest first

1. The per-purchase counter itself (the cap) — first and main line.
2. Per-token rate limit in the proxy (e.g. 10/min) — stops scripted hammering.
3. Global circuit breaker in the proxy (e.g. 2,000 calls/day ≈ $6.40 worst
   case) — beyond it the proxy answers "busy, try again later" honestly.
4. **Prepay billing** on the Gemini API (now the default): we buy credits up
   front, auto-reload **off**. Balance hits $0 → every key stops. A runaway
   bill is structurally impossible — the ceiling is money already spent.
5. AI Studio project monthly spend cap + Cloud Billing **spend-cap budgets**
   (these now genuinely enforce, not just alert): $50/mo on Gemini, $10/mo on
   Cloud Run at launch scale.
6. Google's own enforced Tier 1 ceiling: $250/month, hard-paused.
7. An alerts-only budget across the whole billing account as the tripwire.
8. Endpoint abuse: only verified purchases ever get a JWT; add Play Integrity /
   App Check (free to 10K checks/day, cacheable tokens) once traffic is real.

These numbers are launch-scale speed bumps, raised deliberately as sales fund
them — at 5,000 users the Gemini bill (~$207/mo) needs the caps at ~$300, and
by then gross is six figures. Raising a cap is a decision, not an incident.

## 4 · GCP production setup — the checklist

1. **Gemini Developer API, not Vertex/GEAP.** Google's own guidance: "most
   developers should use the Gemini Developer API." Paid Tier 1 (billing
   linked). The **paid tier does not train on prompts; the free tier does** —
   production never runs on the free tier.
2. **Key migration — time-sensitive.** Google is killing classic API keys:
   standard keys are **rejected from September 2026**. New "auth keys" are
   bound to a service account and restricted to the Generative Language API by
   default. The proxy was built earlier — if its key predates June 2026,
   replace it with an auth key now or extraction dies next month.
3. Prepay: load $50 credits, auto-reload off.
4. Set the AI Studio project spend cap and the two Cloud Billing spend-cap
   budgets ($50 Gemini / $10 Cloud Run), plus one alerts-only budget.
5. Key lives in **Secret Manager**, mounted into Cloud Run. Never in the APK —
   the entire reason the proxy exists, now confirmed as the only sane pattern.
6. **Cloud Run**, scale-to-zero, default concurrency, no min-instances. Cold
   start is sub-second next to 2–5s of model time. Hosting ~$0 to 5K users.
7. **Firestore** for the counter: one doc per token hash. Free tier covers it
   at every scale we can reach.
8. Model — **decided and validated 2026-08-19 (Arnar): gemini-3.5-flash-lite.**
   Side-by-side against 3.6 Flash on real extractions: same quality, ~2x
   cheaper now and ~4x cheaper after 3.6's Jan 2027 price doubling. Thinking
   minimal (Gemini 3 bills thinking as output), structured JSON output. The
   review screen's low-confidence flags remain the quality safety net.
9. Two GCP projects: prod and test, separate keys, separate caps.
10. One Play service account (`androidpublisher` scope) for purchase
    verification + the daily voided-purchases cron.
11. Reality notes (2026-08-19): the studio org already holds working **Tier 3**
    Gemini keys — higher rate limits, a real head start. But **check their
    type**: classic standard keys are rejected from September 2026 even if they
    work today; only auth keys survive. And run the production proxy in its own
    GCP project with its own billing (prepay credits) so no unrelated Workspace
    or billing hiccup can ever take extraction down — the proxy's uptime and
    the org's admin/billing state must be unrelated by construction.

Also relevant: Firebase AI Logic (the "no proxy needed" Google offering) was
evaluated and **cannot do per-user metering** — per-user limits are RPM-only,
one value for all users, no way to tie to a purchase. Our thin proxy stays; the
constraint holds.

## 5 · How users tap more AI when the year's allowance runs out

**Shape: one-off consumable packs that never expire.** Working example:
"+100 rescues — $2.99" (our cost ~$0.32, net after fee ~$2.54). Price is a
later call; the shape is the decision.

- Play mechanics: a consumable product. The proxy verifies it, **credits the
  ledger first, then consumes it server-side** — consumed purchases vanish from
  Google's records, so our ledger is deliberately the only durable record.
- The store listing will show "In-app purchases" next to the price the moment
  the unlock IAP exists — top-ups don't change the label, and "pay once"
  stays accurate marketing for the app itself.
- **Framing rules — the exact inverse of Crouton's mistake** (it charges $24.99
  once, then $1.99/*month* for AI import; that's its angriest review theme):
  1. Disclosed before purchase, on the same card as the cap.
  2. Nothing recurs. Ever. Packs are non-renewing by construction.
  3. The included 600 resets on the **purchase anniversary** and does *not*
     roll over — said plainly, because pretending otherwise is where Adobe's
     forum rage comes from.
  4. **Purchased top-ups never expire** — the loved pattern (1min.AI), and it
     sidesteps the EU voucher/gift-card expiry question entirely.
  5. Everything non-AI stays unlimited forever (the AppSumo "split the value"
     rule — our version is already the brand: typing is always unlimited).
  6. Cost honesty: "each rescue costs real server money" — users accept caps
     they can see the reason for; they revolt at hidden ones (JoggAI's "Not a
     True Lifetime Deal" review) and at base offers that degrade later (Merlin).

**Reset semantics — recommendation: anniversary of purchase.** Calendar year
needs proration explanations; monthly drip is twelve expiry events wearing a
subscription costume. Anniversary matches the pay-once mental model: your year
starts when your ownership did. "The cap can rise, never fall" stays verbatim.

**Onboarding grace — "your first two weeks don't count" (Arnar's idea,
2026-08-19).** For 14 days after a purchase registers, the proxy logs rescues
but doesn't decrement the 600 — same counter machinery, one flag, with a quiet
abuse ceiling (say 300 rescues) inside the window. Why it's smart: the backlog
dump is the one real usage spike — years of saved screenshots imported in week
one could eat a third of the annual allowance at the exact moment of maximum
enthusiasm. The grace makes the cap invisible right then, which is what the
"reward onboarding" research pattern says starter grace is for. Cost, verified:
a 100-screenshot backlog ≈ $0.26 on 3.5 Flash-Lite (~$0.45 on 3.6 Flash);
absolute worst case at the ceiling ≈ $0.78/user; 10,000 buyers averaging 50
grace rescues ≈ $1,600 cumulative against ~$212K net. **Decided 2026-08-19
(agreed with Arnar): every buyer, permanently.** Paywall line: "your first two
weeks of rescues are on the house — clear your backlog." One class of user
forever; the first-100 promo variant was considered and dropped as two-classes
forever. Landing page and Play listing both get this line — it's a differentiator
no subscription competitor can copy cheaply.

**Try-before-buy, assessed and parked.** A pre-purchase trial can't be enforced
without a purchase token — there is no durable identity before purchase, so a
reinstall resets any trial clock (the same hole per-install counting had). The
cost of that abuse is pennies, but a trial re-litigates the hard-paywall bet,
and the evidence cuts both ways (hard paywalls convert ~5x on honest listings;
stingy demos breed dealbreaker reviews). The valve that already exists: Google
Play's self-service refund within 48 hours of purchase is a de-facto trial —
worth stating plainly ("not for you? Play refunds within 48 hours"). Revisit
with closed-test feedback and real refund-rate data; nothing in this design
blocks adding a small free taste (e.g. 3 rescues) later if evidence wants it.

## 6 · What this changes in the plan

1. ~~Constraint 3 wording~~ — **decided: per-purchase counter** (Arnar,
   2026-08-19; `conductor/context.md` updated).
2. Parked "durable cap store" now has its design: Firestore, one doc per token
   hash, increment-in-transaction.
3. Billing seam gets pinned: **free download + $24.99 non-consumable unlock
   IAP** — not an upfront-paid app. A paid app yields no purchase token at all
   (nothing to meter against), and is Family-Library-shareable; the IAP unlock
   is neither. Flutter: `in_app_purchase_android` ≥ 0.5.2 (Billing Library 8 —
   mandatory for updates from Aug 31, 2026; note PBL8 removed purchase-history
   queries, and the unlock must **never** be consumed or it becomes
   unrecoverable client-side).
4. The mandatory 12-tester closed test doubles as the billing test bed: license
   testers get fake cards including a "approves then charges back" card — the
   whole purchase → meter → top-up → clawback pipeline gets proven with no
   real money, before production access even exists.
5. The paywall card copy gains one line under the cap: "Top-up packs available
   if you ever run out — they never expire. Typing is always unlimited."
6. Positioning gain found on the way: one purchase covers **all the user's
   devices** on their Google account — page-safe line: "One purchase, all your
   devices." Family framing stays honest: a shared household account shares the
   book and the cap; separate Google accounts are separate purchases (Play's
   rule, not ours) — never promise "family sharing" as a feature we built.

## 7 · Risks, one sentence each

- If the proxy's Gemini key is a pre-June-2026 standard key, extraction stops
  working when Google rejects standard keys in September.
- If purchases aren't acknowledged server-side within 3 days, Google silently
  refunds every sale.
- If the counter stays per-install in production, clearing app data grants
  infinite free AI and owning two devices halves the cap.
- If the unlock is ever consumed by a code path meant for top-ups, ownership
  becomes unrecoverable on the user's next device.
- If thinking stays enabled on Gemini 3 models, output billing multiplies and
  the per-rescue math above is wrong.
- If a top-up ever auto-renews or the included allowance quietly shrinks, we
  become Crouton's reviews.

## 8 · Unverified flags

Purchase-token string stability across devices is strongly implied by Google's
docs ("globally unique… safely use as a primary key") and confirmed by
community behavior, but no doc states it verbatim — the closed test verifies it
for free. Crouton's "16% of reviews mention charges" is medium confidence.
Google's "tester engagement" checks come from tester-exchange blogs. EU legal
status of in-app credits as vouchers is untested member-state law — "never
expires" makes it moot. Home-cook saving-rate stats are low quality; our own
closed-test proxy data replaces them.

## Key sources

Play Billing: developer.android.com/google/play/billing (security — token as
primary key · lifecycle/one-time — verify/acknowledge/consume · release-notes —
PBL9, Aug 31 2026 mandate · test — license testers, chargeback card · rtdn-
reference) · developers.google.com/android-publisher (productsv2, voided
purchases) · support.google.com/googleplay/android-developer/answer/112622 +
16954621 (fees 2026: 10%+5% first $1M EEA/UK/US) · answer/14372887 (EEA external
offers — personal accounts ineligible) · answer/9858738 (credits are digital
goods, sold via Play) · support.google.com/googleplay/answer/7007852 (IAP not
family-shareable) · pub.dev/packages/in_app_purchase_android/changelog (0.5.2,
PBL8)
GCP/Gemini: ai.google.dev/gemini-api/docs — pricing (3.5-flash-lite $0.30/$2.50,
fetched 2026-08-19) · billing (prepay, tier caps $250/$2,000, spend-based rate
limits) · api-key + interactions/api-key (auth keys, standard keys rejected
Sept 2026) · rate-limits · thinking · deprecations · migrate-to-cloud ("most
developers should use the Developer API") · docs.cloud.google.com/billing/
docs/how-to/budgets-spend-caps (enforcing budgets, Preview) · cloud.google.com/
run/pricing · firebase.google.com/docs/firestore pricing + firebase.blog
increment pattern · developer.android.com/google/play/integrity (10K/day free) ·
firebase.google.com/docs/ai-logic/quotas (per-user limits RPM-only — can't
replace the proxy)
UX/sentiment: shapeof.ai/patterns/cost-estimates · dodopayments.com credits
guide · appsumo.com/blog/lifetime-deals-in-ai-era (split the value, top-up
norms) · helpx.adobe.com generative-credits-faq + community threads (expiry
rage) · ungatedapps.com/app/1461650987 (Crouton AI-behind-subscription reviews) ·
appsumo JoggAI review ("hidden usage limits") · docs.lovable.dev (anniversary
reset precedent) · recime.app/help + samsungfood.com/food-plus +
help.cookbookmanager.com (competitor allowances) · agenticaipricing.com
(the "unlimited" asterisk problem)
