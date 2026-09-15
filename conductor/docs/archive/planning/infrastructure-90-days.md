# Infrastructure at launch — what actually runs, first 90 days

*Written 2026-08-06 for the 11 Dec 2026 → 11 Mar 2027 window. Companion to
docs/first-90-days.md (what you DO) — this is what EXISTS. Architecture of the app itself
lives in docs/architecture-draft.md; this doc is everything around it.*

**Assumption stated up front:** the DittoDatto email work is not visible from this repo, so
this doc assumes it was **Brevo** (the "Bre-something"). If it's a different provider the
shape below doesn't change — one provider, two sending domains. Correct the name and move on.

---

## 1 · The whole system, on one page

```
  PEOPLE'S PHONES                    YOUR ONE SERVER            SOMEBODY ELSE'S PROBLEM
  ┌─────────────────┐                ┌──────────────┐           ┌──────────────────────┐
  │ MyReciBook app  │ ── images ───→ │ thin proxy   │ ── API ─→ │ vision model (paid    │
  │ recipes as JSON │ ←─ recipe ──── │ (Cloud Run)  │           │ per request)          │
  │ in THEIR folder │                │ holds: key   │           └──────────────────────┘
  └─────────────────┘                │ + cap count  │
        │                            └──────────────┘           ┌──────────────────────┐
        │ install + payment ──────────────────────────────────→ │ Google Play          │
        │                                                       │ store · card · VAT   │
        │                                                       │ refunds · payouts    │
  ┌─────────────────┐                                           │ crashes · ratings    │
  │ their Drive /   │ ← their files sync, you never see them    └──────────────────────┘
  │ Dropbox         │
  └─────────────────┘                ┌──────────────┐           ┌──────────────────────┐
                                     │ myrecibook   │           │ Brevo (list email)   │
  people email you ─────────────────→│ .com         │           │ waitlist → launch    │
  support@myrecibook.com             │ landing +    │           └──────────────────────┘
  (forwarded to Gmail)               │ privacy page │
                                     └──────────────┘
```

**Five pieces. One of them is a server you own.** Everything else is either on the user's
phone, in the user's own cloud storage, or a service that already exists.

**What does NOT exist, on purpose:** no user database · no accounts, no login, ever ·
no password-reset email · no Stripe · no analytics pipeline (T3 D8 — telemetry parked) ·
no CRM · no dashboard we build ourselves · no mail server of our own.

## 2 · Email — three different things share that word

This is the part that confuses everyone, so: "email" in our setup means three unrelated
things, and only two of them exist.

### a) The support mailbox — a human address (REQUIRED day one)

`support@myrecibook.com`, forwarded to your Gmail. Namecheap (where myrecibook.com is
registered) includes free email forwarding — no mailbox to run, no server. Then set up
Gmail "send mail as" so your replies leave *from* the domain, not from your personal Gmail.

- Cost: 0. Setup: ~20 min, one MX record + a Gmail confirmation click.
- Play requires a contact email on the listing; T4 already lists this as a launch item.
- What breaks if ignored: your only channel to a paying customer is your personal Gmail,
  which looks amateur and can't be handed to anyone later.

### b) List email — the waitlist and the launch announcement (Brevo, or DD's provider)

The Gate-2 landing page collects signups. On launch day those people get one email. That's
list email, also called **marketing email**, and it needs a real provider — you cannot send
200 emails from Gmail without landing in spam.

Reuse DD's account: one provider can hold two lists with two sending identities. You already
did the hard part once (domain authentication), so this is repetition, not new learning.

Three DNS records make it work — **SPF, DKIM, DMARC**. Plain words: they are public notes
attached to your domain that say "this company is allowed to send mail as myrecibook.com,
and here's how to check the signature." Without them, the launch email you spent months
earning goes straight to spam and you never find out.

- Cost: Brevo's free tier covers a few hundred sends a day — far above our needs.
- Setup: ~1 h including DNS propagation waiting.

### c) Email FROM the app — does not exist

No accounts means no verification mails, no password resets, no notifications. The app
never sends email. This deletes an entire category of infrastructure, and it's a direct
consequence of "no login ever" — worth saying out loud when someone asks why we don't need
an email service in the product.

**Do not run your own mail relay.** Running SMTP means fighting deliverability and spam
reputation forever, for a solo dev, to save maybe €0. It is the single worst use of your
hours in this whole project.

**GCP is not the answer for email.** Google Cloud is where the proxy runs and where you
watch cost. It has no simple "send my newsletter" service. Different tool, different job.

## 3 · The dashboard — you don't build one, you open three tabs

| Tab | What it tells you | Cost | Time/wk |
|---|---|---|---|
| **Google Play Console** | installs, buyers, revenue, ratings, reviews, crashes (Android vitals) | free | 20 min |
| **GCP console** — billing + Cloud Run logs | is my one server on fire, and what did it cost | free to look | 5 min |
| **Brevo** | did the launch email arrive and get opened | free tier | 5 min, launch week only |

Play Console **is** the business dashboard. It already exists, it's free, and it has the
four numbers from docs/first-90-days.md §2. Building our own would mean re-implementing
Google's reporting for an audience of one person.

### DittoDatto Business Portal — honest verdict: no, and here's the useful half

The instinct isn't stupid, it's just pointed the wrong way. Feeding MyReciBook numbers into
a DD portal means (a) app data leaving the user-owned model and landing in a second system
you also have to maintain, and (b) hours spent rebuilding numbers Play gives free. At 20–500
users that's pure cost.

The reuse that *is* real runs the other direction:

1. **DD's email plumbing** — same provider, same domain-authentication muscle memory. Reuse.
2. **DD's registered users as an audience** — a discounted MyReciBook unlock for DD users is
   a genuine launch channel that costs nothing to try. Play supports promo codes for exactly
   this (check the per-quarter quota when it's real, not now).
3. **The shared design system** — already happening (T3: DittoDatto tokens → theme.dart).

Revisit a shared portal only if there's ever a second shipped product with real users.
Two products, one portal, is a real idea. One product, one portal, is a hobby.

## 4 · The money plumbing — Google does all of it

Google Play is **merchant of record**: it takes the card, charges the right VAT for the
buyer's country, handles refunds, and pays you out to your bank on a monthly cycle. You
build no billing system, hold no card data, issue no invoices.

Your side is one in-app product (D10: 3 free imports → ~$25 unlock) plus a bank account and
tax details in the Play Console payments profile.

Service fee, verified Aug 2026: since 30 Jun 2026 in the EEA the fee starts at **10%** on the
first $1M/year, **+5%** if you use Play's billing system — so budget ~15% off the top.

## 5 · What it costs to run, monthly

| Item | Cost at 20–500 users |
|---|---|
| Domain (myrecibook.com) | ~$1–2/mo amortised |
| Landing page hosting (static: Cloudflare Pages / Netlify) | $0 |
| Cloud Run proxy | ~$0 — scales to zero, free tier covers this volume |
| Support mailbox (Namecheap forwarding) | $0 |
| Brevo free tier | $0 |
| **Vision model calls** | **the only real variable — cents per extraction** |

Everything is free or near-free except the extraction calls. That single line is why
constraint 2 requires a stated fair-use cap: revenue arrives once, extraction cost recurs
forever, and one heavy user can out-eat what they paid. Pin the actual per-extraction number
in the cap-math session before the listing copy is written.

## 6 · Secrets and keys

- The model API key **never ships inside the APK**. That is the entire reason the proxy
  exists (architecture-draft §5). Production key lives in Cloud Run's environment /
  Secret Manager.
- Alpha exception already decided (T3 D2 / P5): a restricted, capped dev key may sit in the
  closed-track APK for the ~6-week test window with 12 known testers. That exception dies
  before production.
- Storage client IDs (Drive, Dropbox) live in `.env` → `app/dev.env`, gitignored. Production
  errands are already parked in pulse: Dropbox production approval, Play-signing SHA-1 added
  to the Drive client.

## 7 · Legal surface — thin, because of the architecture

- **Privacy policy page** on myrecibook.com — Play requires a public URL (T4 item).
- **Play Data Safety form** — must declare that images are sent to a server for processing.
- **No account, no recipe database on your side** — so there is almost nothing to hand over
  or delete under GDPR. The user's data is in the user's own folder. This is a real benefit
  of the bet, not just a nice story.
- **Income and NAV / company formation:** money from an app while receiving benefits has
  reporting rules, and forming Merkurial-Studio changes how income is taxed. Check with NAV
  and an accountant before the first payout lands — not with me. I'm not a lawyer or a
  financial advisor, and this is the kind of thing that is cheap to ask about early and
  expensive to fix late.

## 8 · Build order for the infrastructure itself

Nothing here is due now. Sequence, not schedule:

1. Support mailbox forwarding + Gmail send-as — 20 min. Needed for the listing.
2. Privacy policy page on the landing site — 1 h. Needed for the listing.
3. Waitlist form → Brevo list, domain authenticated — 1 h. Needed for Gate 2 (landing 2 Sep).
4. Thin proxy on Cloud Run, key moved out of the APK — parked as D2, due before 11 Dec.
5. Play payments profile + tax details — 1 h, and it can hold up a release, so not last.

Everything else on this page already exists or costs nothing.
