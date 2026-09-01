# First 90 days after launch — the operating playbook

*Written 2026-08-06, for the window 11 Dec 2026 → 11 Mar 2027. Plain words on purpose.
Not strategy (that's context.md), not marketing venues (docs/marketing-channels.md).
This is: what you actually do each week, what the words mean, and what to say to people.*

---

## 1 · The weekly loop — four moves, ~4.5 hours

This is the whole job at small scale. Same four moves, every week, boring on purpose.
Budget check: 4.5 h is inside the ≤10 hr/wk cap (context.md constraint 5).

| # | Move | Time | Where |
|---|------|------|-------|
| 1 | Read the four numbers, write one line in pulse | 30 min | Play Console |
| 2 | Answer every support email the same day | 30 min | support mailbox |
| 3 | Ship ONE fix, chosen by the leaking number | 2–3 h | the repo |
| 4 | One act of distribution — a post, a reply, a thread | 1 h | docs/marketing-channels.md |

Rule for move 3: if you can't name which number the fix moves, it isn't work, it's
comfort. Write the number in the commit message.

Rule for move 4: this is the hour you will skip, and it is the hour that matters most
at 20 users. Nobody installs an app they never heard of.

## 2 · The four numbers

| Number | What it counts | If it's low, this is what's broken |
|---|---|---|
| Installs | people who tapped "install" | nobody sees it — distribution, not code |
| Activation | saved a real recipe on day one | extraction quality or the first-run flow |
| Hit the wall | used all 3 free imports | app isn't useful enough to come back to |
| Unlocks | paid the one-time fee | price, trust, or the paywall wording |

Watch them as a **trend across weeks**, never as a total. A total hides the week
everything changed.

## 3 · The five moments — what it actually feels like

1. **First sale.** A number that said 0 says 1. A stranger decided your app was worth
   more than a coffee. **Do nothing.** One sale proves the door opens, nothing else.
2. **First support email.** The real milestone. Somebody cared enough to write instead
   of deleting. Reply the same day, in human words. At this size, personal replies are
   the entire marketing department.
3. **First bad review.** Public and permanent, and it will sting because you built this
   alone. Reply politely underneath — future visitors read the reply more than the
   complaint — fix the thing, move on.
4. **The quiet week.** No sales, no email, nothing. This is normal and it is where most
   solo apps quietly die: not from failure, from silence. Silence is a talking problem,
   not a code problem. Cure = move 4.
5. **The rhythm.** Weeks 4–12 are the same loop repeated. That's the business.

## 4 · The words, in plain language

**Install** — someone downloaded it. **Active install** — downloaded and not deleted yet.
The gap between the two is the honest number.

**Activation** — the person got real value once (for us: saved one real recipe).
Downloading is not using.

**Conversion** — of the people who tried it, how many paid. A small percentage is normal.

**Retention** — do they open it again next week.

**Churn** — people cancelling. It's a *subscription* word; it does not apply to us. Nobody
can cancel a one-time purchase. People just quietly stop opening the app.

**Cohort** — one group of people who arrived in the same week, followed as a group.
Useful because "everyone since launch" hides what changed.

**Refund** — the buyer asks Google for the money back. Google auto-refunds within 2 hours
of purchase and may refund up to 48 hours at its discretion. After that they're told to
contact you. It happens; it is not an insult.

**Rating vs review** — the rating is the stars, the review is the words. Stars decide
whether new people even look at the listing.

**ARPU** — average money per user. For us it's just the price minus Google's cut minus
refunds.

**LTV** — lifetime value, all the money one customer ever brings. Pay-once means LTV is
one payment, forever. This is why every new dollar must come from a new person.

**ASO** — app store optimisation: the title, screenshots and words that decide whether a
Play visitor installs. Listing work, not code work (docs/marketing-channels.md §6).

**IAP** — in-app purchase. Ours is one non-consumable unlock (D10: 3 free → ~$25).

**Merchant of record** — who legally sells to the customer and owes the tax. For us that's
Google, not you. It's why there's no Stripe and no invoices in our infrastructure.

## 5 · Ready-made replies

Keep these in a notes file and edit per case. Speed beats polish.

**First support email — extraction came out wrong**
> Hi — sorry about that, and thank you for writing. Could you send me the screenshot you
> tried? I read every one of these myself and it usually tells me exactly what to fix.
> If the recipe is important to you and you'd rather not wait, you can also fix the fields
> on the review screen before saving. — Arnar

**Bad review reply (public, under the review — write for the next reader, not the angry one)**
> Thanks for the honest review. [One sentence naming the exact problem, no excuses.]
> [What you're doing about it, and roughly when.] If you email support@myrecibook.com I'll
> follow up personally.

**Refund request after Google's window**
> Of course — no hard feelings. Here's how to request it: [Play refund link]. If Google
> declines it, write back and I'll sort it out. Would you tell me what didn't work? It
> genuinely helps.

**A feature request you won't build**
> That's a good idea and I've written it down. I'm one person, so I'm keeping the app
> small on purpose — [the thing you ARE working on] comes first. I'll tell you if this
> one lands.

**Somebody asks "why pay once instead of subscription?"**
> Because your recipes are yours. They're plain files in your own folder, and the app
> keeps working whether or not I'm still around. A subscription would mean holding them
> hostage, and I didn't want to build that.

## 6 · What NOT to do in the first 90 days

- Don't add features to fix a distribution problem. Silence needs posts, not code.
- Don't rewrite anything. Nothing at 20–500 users is a scale problem.
- Don't build a dashboard. Play Console is the dashboard (docs/infrastructure-90-days.md).
- Don't run a discount before you know the price is the problem. Cutting price on an app
  nobody has seen just makes the same zero, cheaper.
- Don't answer support at 3am and then vanish for a week. Same-day, then closed.

## 7 · The one honest checkpoint

Gate 3 (context.md) lands Thu 11 Mar 2027: under 1,000 installs OR under $500 total
revenue → stop building, leave it listed, keep it as portfolio. That date exists so a
small result doesn't quietly eat all of 2027. It is not a judgement on the work.
