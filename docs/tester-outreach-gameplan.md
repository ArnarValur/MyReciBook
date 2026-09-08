# Testers & outreach — gameplan

*Researched 2026-09-08 (Cowork, three research passes, key claims re-verified). Sequence, not schedule. Rules and counts rot — re-read a sub's sidebar the day you post.*

## The gate we're actually solving

Play requires **12 testers opted in, continuously, for 14 days** before a personal account gets production access. Google also bounces applications for *insufficient engagement*, and the form asks how you recruited testers and what feedback you got. A tester who opts out and back in resets their own clock.

Google's requirement is 12. **Recruit more than 12** (a buffer of 6–8 extra) because one tester opting out drops you below the line and restarts the clock. At least a third should be real home cooks who actually import a recipe, not swap-partners tapping "open" once a day.

Two pools, two jobs:

1. **Gate pool** (swap communities) — keeps the 12-count above water.
2. **Real pool** (cooks) — produces the feedback answers on the form and the first honest reviews.

## Phase 1 — get the closed test rolling (do this first, with any build)

The clock only runs while 12+ are opted in, so start before the build is "ready".

Setup: one Google Group, "anyone can join", as the tester list. Post both the Play opt-in link and the web opt-in link every time.

**Gate pool — free swap communities (post the same short ask in all of them, same day):**

| Where | Size | Note |
|---|---|---|
| r/alphaandbetausers | ~45k | Built for this. Tag `[Android, Beta]`, link the Play page directly, no email-only signup. |
| r/AndroidAppTesters | ~10k | State the Android version; ask mods for a dev flair. |
| r/betatests | ~14k | Mostly Android closed-testing posts. |
| r/TestersCommunity + Testers Community app | ~21k | Free "Packs" of 16 devs who open each other's apps daily for 16 days; inactive members auto-kicked. Best free option on paper. |
| TestHive Discord | ~5.4k | discord.com/invite/Mfz8RgJ7gq |
| RevenueCat Shipaton Discord | — | has a `#looking-for-google-play-tester` channel |

Norm: you test back. 12 partners means you open 12 strangers' apps daily for two weeks. Budget 10 minutes a day for it.

**Skip:** r/androiddev and r/FlutterDev remove "need testers" posts within hours unless there's a pinned thread. Fiverr "12 testers for $10" gigs — a documented outcome was 12 Gmail addresses, 2 opt-ins, 0 opens. Emulator farms trip Play Integrity and cost you the 14 days over again.

**Paid fallback (only if free stalls):** onTest / PrimeTestLab / TestFi at ~$20–40 claim real devices. Unverifiable, every "2026 policy update" article is written by one of them. If used: once, disclosed on the form, and still keep real users in the pool.

**Real pool — cooks:**

- r/androidapps (574k) — the single best fit. Rule: `[Self Promo]` flair, **max once per 45 days**, must engage in the thread. One honest post: "I built a screenshot-to-recipe app, no account, files stay on your phone, one-time price. Want 20 Android testers." Answer every comment. Spend the 45-day slot on the tester call, not on launch — launch has other channels.
- Own network — 4–6 people who actually cook. Friends, family, colleagues in Norway. These are the ones who will say "the ingredient parser missed *smør*".
- Norwegian-language ask in Diskusjon.no (Mobil section) and the Matprat.no Facebook group; Icelandic ask in "Hollar uppskriftir" FB group. Small, warm, and nobody else is there.

## Phase 2 — cooking communities (feedback + first fans, during the test)

The cooking subs are hostile to promo. This is a **participate, don't pitch** phase.

| Sub | Size | Rule | Play |
|---|---|---|---|
| r/EatCheapAndHealthy | 11.5M | *explicitly* bans "app testers" | Skip entirely |
| r/Cooking | 6.3M | no ads of any kind | Comment helpfully, never link |
| r/MealPrepSunday | 5.8M | no advertising/surveys | Same |
| r/cookingforbeginners | 2.2M | self-promo only in megathread; links in comments OK | Post once in the megathread; answer "how do I keep recipes?" comments |
| r/recipes | 3.6M | has an "Online recipe organizers" wiki page | Modmail asking to be listed |
| r/Cookbooks | 15k | Saturday self-promo thread | Low priority |
| r/ADHD | 2.3M | bans promo | Positioning angle only, as the brief already says |
| r/degoogle | 545k | tolerated if the privacy angle is real | "No account, files on your phone" post — expect "is it open source?" |

Discord: The Cooking Server (~10.6k), The Cooking Club (~7.3k) — ask mods for a self-promo channel before posting.

## Phase 3 — displaced users (the free lunch)

Three groups of people are looking for a new recipe home right now:

- **MasterCook.com cloud closes 31 Dec 2026.** Verified on dvo.com. Their free `.mz2` backup export dies with it.
- **Paprika 4** (verified, support article 14 Jul 2026): new features — including AI photo scan and social import — will be **subscription-only**. Paprika's one-time-purchase crowd is exactly our buyer, and "photo scan" is our front door.
- **Copy Me That** revoked "lifetime" purchases and moved to a 40-recipe cap; **ReciMe** $40–60/yr with forced-trial complaints; **Samsung Food+** $60/yr; **Yummly** (Dec 2024) and **PlateJoy** (Jul 2025) already shut.

Play: comment, don't post, on "Paprika 4 subscription", "MasterCook closing", "ReciMe alternative" threads with an import path. Prerequisite: one "Moving from X" help page per app on the website — that's the link we put in the comment. Which imports we actually support decides which pages we can honestly write (see `library-import-research.md`).

## Phase 4 — launch listings (the day the Play page is live)

Free, high-odds, long-tail — these feed "Paprika alternative" search traffic for years:

- **AlternativeTo** — Suggest new application; tag licence "One-time purchase", "No registration required", "Offline"; suggest Paprika, ReciMe, Recipe Keeper, Mela as alternatives. Approved in 1–2 days. The most important listing on this page.
- **SaaSHub**, **Launching Next** — free listings, same day.
- **Slant** — add MyReciBook as an option under existing "best recipe manager" questions.
- **BetaList** — pre-launch, Oct–Nov, for the 200-signup target.
- **Uneed**, **MicroLaunch**, **Peerlist** — launch week; free listing on Uneed keeps its link only above 10 upvotes.
- **Show HN** — Tue–Thu, 9–12 ET. "No account, one JSON file per recipe, pay once" is HN-shaped. No vote-asking, no AI-written text.
- **Product Hunt** — editors hand-pick now; several 2026 write-ups call it net-negative for solo makers. Do it for the backlink, expect nothing.
- **Google Play featuring nomination** — Play Console form, apps launched in the last 4 months, rating ≥3.0. Submit in the first weeks after launch. Indie festivals are games-only; skip.

## Phase 5 — press and creators (pitch 7–10 days before launch, embargo + free code)

**Best odds first:**

1. **Kode24** (hei@kode24.no) — "Norwegian solo Flutter dev ships pay-once, no-account recipe app" is a real developer story for them.
2. **Android Authority** (tips@androidauthority.com) — covers indie apps most regularly of the big three.
3. Byline authors of standing "best recipe apps" roundups (TechRadar, Tom's Guide, Lifehacker, MakeUseOf, Zapier) — pitch the author, not the inbox; one line: "the only pay-once Android app with screenshot import". Paprika currently owns the "best one-time purchase" slot in every roundup — that slot is the target.
4. **Rich DeMuro** (richontech.tv) — has an independent "save your recipe collection" roundup.
5. **ADDitude** — editorial, runs meal-app pieces; "photo of a recipe → done, no planning tax".
6. Android Police (editorial@androidpolice.com), 9to5Google (tips@9to5g.com), Digi.no (tips@digi.no), Tek.no (tips@tek.no) — one clean pitch each with press kit, once.

**Creators (send a tester key + a 30-second screenshot→recipe demo):**

| Creator | Subs | Why |
|---|---|---|
| Cooking and Calm | 36k | Instagram→Paprika hacks — closest match to our front door |
| The Savvy Professor | 72k | "Best recipe organizer apps iPhone & Android" |
| A Better Computer | 40k | Paprika/Mela/Pestle comparison |
| Hey, Ivan! | 50k | Paprika overview |
| Kenta Pogo | 15k | "Best free recipe apps for Android 2026" |
| How to ADHD / ADHDVision / Caren Magill | 1.95M / 492k / 143k | ADHD productivity-tool roundups — long shot, big upside |

**Bloggers:** mid-tier food Substacks (5–30k subs) and Food Blogger Pro members. The angle is honest and theirs: "your readers screenshot your recipes anyway — MyReciBook keeps your URL and attribution on the card." Free code per blogger.

## What needs to exist before each phase

- Phase 1: a closed-test build, the Google Group, a 3-line tester ask (Norwegian + English + Icelandic).
- Phase 2: nothing new — an honest account with comment history.
- Phase 3: "Moving from X" pages on the website; a verified list of which exports we import.
- Phase 4: the live Play page, 4–6 screenshots, a 1-paragraph description, AlternativeTo account.
- Phase 5: a press kit (logo, screenshots, one-paragraph story, promo codes) on the website; blog post on Arnar's site to link to.

## Sources

Play rule: https://support.google.com/googleplay/android-developer/answer/14151465 · Paprika 4 subscription: https://paprikaapp.zendesk.com/hc/en-us/articles/41887059110167 · MasterCook closure: https://www.dvo.com/mastercook-faq.php · Tester-swap comparison: https://ontest.app/blog/how-to-get-12-testers-for-google-play-closed-testing · Testers Community: https://www.testerscommunity.com/how-to-find-beta-testers-for-android-apps · RevenueCat 14-day guide: https://www.revenuecat.com/blog/engineering/google-play-14-day · AlternativeTo FAQ: https://alternativeto.net/faq · Show HN guide: https://favors.dev/blog/show-hn-launch-guide · Product Hunt 2026: https://getlaunchlist.com/blog/how-to-launch-on-product-hunt-2026 · ReciMe review: https://www.recipeone.app/blog/recime-app-review · Samsung Food review: https://www.plantoeat.com/blog/2026/01/samsung-food-review-pros-and-cons/ · Rich DeMuro: https://richontech.tv/p/best-apps-to-save-your-recipe-collection · TechRadar roundup: https://www.techradar.com/news/best-recipe-apps-the-7-finest-apps-for-cooking-inspiration · ADDitude: https://www.additudemag.com/how-to-eat-healthy-nutrition-apps-tools/ · Subreddit rules read via sidebars 2026-09-08 (re-check before posting).
