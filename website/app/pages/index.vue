<script setup lang="ts">
// Card-box landing — ported from the design canvas
// "MyReciBook Website Card Box" (docs/MyReciBook Flutter website-2-mockups.zip).
// Copy audit lives in website/copy-notes.md — canvas claims not yet confirmed
// against the app are flagged there, not silently rewritten.

useSeoMeta({
  title: 'MyReciBook — Rescue the recipes buried in your camera roll',
  description:
    'MyReciBook turns recipe screenshots, links and handwritten cards into a cookbook you own. Plain files on your phone. Pay once. Cook forever. Android.',
  ogTitle: 'MyReciBook — Rescue the recipes buried in your camera roll',
  ogDescription:
    'Screenshots, links and grandma\'s cards become a cookbook you own — plain files, on your phone. No subscription. No account. Ever.',
  ogType: 'website',
  ogImage: 'https://myrecibook.com/og.png',
  ogImageWidth: 1200,
  ogImageHeight: 630,
  twitterCard: 'summary_large_image',
})

const tilts = ['-1.1deg', '.7deg', '-.5deg', '.9deg', '-.8deg', '.5deg']

const features = [
  { icon: 'i-material-symbols:timer-rounded', tab: 'Card 04', title: 'Cook mode', body: 'One step at a time in big, kitchen-proof type. Tap zones sized for floury thumbs, timers built in.' },
  { icon: 'i-material-symbols:checklist-rounded', tab: 'Card 05', title: 'Grocery list', body: '“9 items · from 3 planned recipes” — merged, deduplicated, and it asks before combining 2 lemons with 4.' },
  { icon: 'i-material-symbols:kitchen-rounded', tab: 'Card 06', title: 'Pantry', body: "Know what's on the shelf. Categories fold away, recents float up, and the grocery list checks against it." },
  { icon: 'i-material-symbols:restaurant-rounded', tab: 'Card 07', title: 'Food diary', body: 'Log meals straight from your recipes and pantry — no double typing. Trends show your week without the guilt trip.' },
  { icon: 'i-material-symbols:barcode-scanner-rounded', tab: 'Card 08', title: 'Barcode scanner', body: 'Point it at the package. Open Food Facts fills in the product and its nutrition — most countries covered.' },
  { icon: 'i-material-symbols:monitoring-rounded', tab: 'Card 09', title: 'Nutrition tracking', body: 'Energy, macros and micros per day, week and year — with coverage you can actually see, not just totals.' },
].map((f, i) => ({ ...f, tilt: `rotate(${tilts[i]})` }))

const heroChecks = [
  'Made for Android',
  'Your recipes stay on your phone',
  'Typing them in is always unlimited',
]

const priceChecks = [
  'Everything — cookbook, cook mode, grocery, pantry, diary',
  '1,200 AI rescues a year — fair-use cap, in writing',
  'Typing recipes in yourself — always unlimited',
  'Ran out? Top up the AI — still no subscription',
]
</script>

<template>
  <div>
    <!-- ── Hero: the front card of the box ─────────────────── -->
    <section id="top" class="hero">
      <!-- scattered cards behind: where it ends, where it starts -->
      <div class="scatter scatter-done" aria-hidden="true">
        <img src="/screenshots/tiramisu.webp" alt="">
      </div>
      <div class="scatter scatter-photo" aria-hidden="true">
        <img src="/screenshots/handwritten.webp" alt="">
        <span>IMG_2041.jpg — grandma's card</span>
      </div>

      <div class="hero-card paper ruled margined">
        <CardTape style="left: -26px; top: -12px; transform: rotate(-38deg)" />
        <CardTape style="right: -30px; top: 16px; transform: rotate(42deg)" />

        <div class="card-heading">
          <span class="card-no">RECIPE Nº 001</span>
          <span class="card-from">From the kitchen of · you</span>
        </div>
        <h1 class="hero-title">
          Rescue the recipes buried in your <span class="hero-mark">camera roll.</span>
        </h1>
        <p class="hero-lede">
          MyReciBook reads screenshots, links and handwritten cards — and files
          them into a cookbook you actually own. On your phone, like a card in
          a box. No subscription. No account. Ever.
        </p>
        <div class="hero-ctas">
          <a href="#price" class="cta">
            <UIcon name="i-material-symbols:photo-library-rounded" class="cta-icon" />Rescue your first recipe
          </a>
          <a href="#recipe" class="cta-quiet">Read the recipe for this app ↓</a>
        </div>

        <div class="marginalia hero-marginalia" aria-hidden="true">
          grandma's handwriting welcome — we read cursive
        </div>
        <div class="stamp" aria-hidden="true">Pay once<br>cook forever</div>
      </div>

      <div class="hero-checks">
        <span v-for="c in heroChecks" :key="c" class="check">
          <UIcon name="i-material-symbols:check-rounded" class="check-icon" />{{ c }}
        </span>
      </div>
    </section>

    <!-- ── The pitch, as a recipe ───────────────────────────── -->
    <section id="recipe" class="section">
      <div class="recipe-card paper">
        <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(-1deg)" />
        <div class="recipe-head">
          <span class="card-no">RECIPE Nº 002</span>
          <h2 class="recipe-title">A cookbook you own</h2>
          <span class="recipe-meta">Prep: 30 sec · Serves: you, forever</span>
        </div>
        <div class="recipe-grid">
          <div>
            <div class="col-label">Ingredients</div>
            <div class="ingredients">
              <span class="ing"><span class="ing-box" /><span><strong>1</strong> camera roll full of screenshots</span></span>
              <span class="ing"><span class="ing-box" /><span><strong>1</strong> Android phone</span></span>
              <span class="ing"><span class="ing-box" /><span><strong>1,200</strong> AI rescues a year — top-ups if you run out</span></span>
              <span class="ing"><span class="ing-box" /><span><strong>0</strong> subscriptions, <strong>0</strong> accounts</span></span>
              <span class="ing"><span class="ing-box" /><span>a pinch of patience while it reads cursive</span></span>
            </div>
          </div>
          <div>
            <div class="col-label">Method</div>
            <div class="method">
              <div class="step"><span class="step-no">1.</span><p>Share a screenshot, paste a link, or snap grandma's card with the camera.</p></div>
              <div class="step"><span class="step-no">2.</span><p>The AI turns it into a proper recipe — ingredients, steps and timings — and shows you the result to review before it's saved.</p></div>
              <div class="step"><span class="step-no">3.</span><p>File it in your book. It lives on your phone; export a PDF or document whenever you like.</p></div>
            </div>
          </div>
        </div>
        <div class="marginalia spine-note" aria-hidden="true">tested 1,200 times a year</div>
      </div>
    </section>

    <!-- ── The cards (features as index cards) ─────────────── -->
    <section id="cards" class="section">
      <div class="cards-head">
        <h2 class="h2">What's filed in the box</h2>
        <span class="flip-hint">flip through ↓</span>
      </div>
      <div class="cards-grid">
        <div v-for="f in features" :key="f.title" class="feature" :style="{ transform: f.tilt }">
          <span class="feature-tab">{{ f.tab }}</span>
          <div class="feature-card paper ruled-tight">
            <div class="feature-head">
              <UIcon :name="f.icon" class="feature-icon" />
              <span class="feature-title">{{ f.title }}</span>
            </div>
            <p class="feature-body">{{ f.body }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Taped-in phone ───────────────────────────────────── -->
    <section class="section">
      <div class="pocket-grid">
        <div>
          <h2 class="h2 pocket-title">The box, in your pocket.</h2>
          <p class="pocket-lede">
            Coverless recipes get a hand-me-down gradient cover, picked by the
            title so it never changes. Search, filters and your shelves — one
            thumb, one screen.
          </p>
          <div class="pocket-points">
            <span><UIcon name="i-material-symbols:barcode-scanner-rounded" class="point-icon" />Barcode scanner with Open Food Facts behind it — most countries covered</span>
            <span><UIcon name="i-material-symbols:monitoring-rounded" class="point-icon" />Nutrition trends by day, week and year — no guilt trip</span>
            <span><UIcon name="i-material-symbols:dark-mode-rounded" class="point-icon" />Stitch Slate by day, Midnight by night</span>
          </div>
        </div>
        <PhoneMockup src="/screenshots/cookbook.webp" />
      </div>
    </section>

    <!-- ── One rescue, photographed (real screenshots) ──────── -->
    <section id="rescue" class="section">
      <div class="cards-head">
        <h2 class="h2">One rescue, start to finish</h2>
        <span class="flip-hint">real screenshots, not mockups</span>
      </div>
      <div class="strip">
        <figure class="photo" style="transform: rotate(-1.6deg)">
          <CardTape style="left: 50%; top: -12px; width: 90px; height: 26px; transform: translateX(-50%) rotate(-2deg)" />
          <img src="/screenshots/rescue-source.webp" alt="A recipe screenshot buried in the camera roll" loading="lazy">
          <figcaption><span class="step-tag">1</span>The screenshot, as found</figcaption>
        </figure>
        <div class="strip-arrow" aria-hidden="true">→</div>
        <figure class="photo" style="transform: rotate(0.9deg)">
          <CardTape style="left: 50%; top: -12px; width: 90px; height: 26px; transform: translateX(-50%) rotate(2deg)" />
          <img src="/screenshots/rescue-review.webp" alt="The rescued recipe, shown for review before saving" loading="lazy">
          <figcaption><span class="step-tag">2</span>Rescued — you review before it's saved</figcaption>
        </figure>
        <div class="strip-arrow" aria-hidden="true">→</div>
        <figure class="photo" style="transform: rotate(-0.7deg)">
          <CardTape style="left: 50%; top: -12px; width: 90px; height: 26px; transform: translateX(-50%) rotate(-1deg)" />
          <img src="/screenshots/recipe-page.webp" alt="The finished recipe page, converted to metric" loading="lazy">
          <figcaption><span class="step-tag">3</span>Filed in your book — in your units</figcaption>
        </figure>
      </div>
      <div class="marginalia strip-note" aria-hidden="true">cups became grams on the way — you're welcome</div>
    </section>

    <!-- ── The price card ───────────────────────────────────── -->
    <section id="price" class="section section-far">
      <div class="price-card paper ruled margined-tight">
        <div class="onetime" aria-hidden="true">One-time</div>
        <div class="card-no price-no">RECIPE Nº 003 · THE PRICE</div>
        <div class="price-row">
          <span class="price">$24.99</span>
          <span class="price-note">once. Like a good knife.</span>
        </div>
        <div class="price-rule" />
        <div class="price-checks">
          <span v-for="c in priceChecks" :key="c" class="check price-check">
            <UIcon name="i-material-symbols:check-rounded" class="check-icon" />{{ c }}
          </span>
        </div>
        <div class="marginalia price-marginalia" aria-hidden="true">the cap resets 1 January, by the way</div>
        <a href="#" class="cta cta-block">
          <UIcon name="i-material-symbols:download-rounded" class="cta-icon" />Get MyReciBook
        </a>
        <div class="price-fine">No subscription. No account. Ever. · Made for Android</div>
      </div>
    </section>

    <!-- ── Keep it (ownership pocket) ───────────────────────── -->
    <section id="yours" class="section section-far">
      <div class="yours">
        <h2 class="h2 yours-title">If MyReciBook vanished tomorrow,<br>your recipes wouldn't.</h2>
        <p class="yours-lede">
          Your cookbook lives on your phone — not on someone else's server.
          Back it up to your Drive, export any recipe as a PDF or document,
          share it however you like. Nothing to shut down.
        </p>
        <div class="envelope">
          <div class="slip" style="transform: translateX(-150%) rotate(-4deg); bottom: 104px">
            <UIcon name="i-material-symbols:picture-as-pdf-rounded" class="slip-icon" />PDF
          </div>
          <div class="slip" style="transform: translateX(-50%) rotate(1deg); bottom: 112px">
            <UIcon name="i-material-symbols:description-rounded" class="slip-icon" />Document
          </div>
          <div class="slip" style="transform: translateX(50%) rotate(5deg); bottom: 100px">
            <UIcon name="i-material-symbols:send-rounded" class="slip-icon" />Send a copy
          </div>
          <div class="envelope-front">
            <span>Yours · Printable · Portable</span>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* ── Hero ────────────────────────────────────────────────── */
.hero {
  max-width: 1040px;
  margin: 0 auto;
  padding: 72px 24px 20px;
  position: relative;
}
.scatter {
  position: absolute;
  border: 1px solid var(--box-line);
  border-radius: 6px;
  box-shadow: var(--box-shadow-sm);
}
.scatter img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top;
}
.scatter-done {
  left: 2%;
  top: 34px;
  width: 230px;
  height: 165px;
  overflow: hidden;
  background: #f7efe0;
  border-color: rgba(120, 90, 50, 0.2);
  transform: rotate(-6deg);
}
.scatter-photo {
  right: 4%;
  top: 20px;
  width: 210px;
  height: 150px;
  overflow: hidden;
  transform: rotate(5deg);
  background: #eeeef0;
}
.scatter-photo span {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 6px 10px;
  font-size: 10.5px;
  color: var(--box-ink-soft);
  background: rgba(255, 255, 255, 0.78);
}
.hero-card {
  max-width: 780px;
  margin: 0 auto;
  box-shadow: var(--box-shadow-lg);
  transform: rotate(-0.7deg);
  padding: 58px 64px 50px;
}
.card-heading { display: flex; align-items: baseline; gap: 12px; margin-bottom: 26px; }
.card-from {
  font-size: 11px;
  letter-spacing: 0.9px;
  text-transform: uppercase;
  color: rgba(69, 70, 82, 0.55);
}
.hero-title {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: clamp(36px, 4.4vw, 54px);
  line-height: 1.08;
  letter-spacing: -0.02em;
  margin: 0 0 20px;
  color: var(--box-ink);
}
.hero-mark {
  color: var(--box-primary);
  border-bottom: 3px solid rgba(36, 56, 156, 0.3);
}
.hero-lede {
  font-size: 16.5px;
  line-height: 1.95;
  color: var(--box-ink-soft);
  margin: 0 0 30px;
  max-width: 520px;
  text-wrap: pretty;
}
.hero-ctas { display: flex; gap: 14px; align-items: center; flex-wrap: wrap; }
.hero-marginalia {
  position: absolute;
  right: 26px;
  bottom: 6px;
  transform: rotate(-3deg);
  max-width: 170px;
}
.stamp {
  position: absolute;
  right: 44px;
  top: 40px;
  transform: rotate(8deg);
  border: 2.5px solid rgba(36, 56, 156, 0.4);
  border-radius: 6px;
  padding: 6px 12px;
  font-family: ui-monospace, 'SF Mono', Menlo, monospace;
  font-size: 11px;
  letter-spacing: 2px;
  color: rgba(36, 56, 156, 0.55);
  text-transform: uppercase;
}
.hero-checks {
  text-align: center;
  margin-top: 30px;
  font-size: 12.5px;
  color: var(--box-ink-faint);
  display: flex;
  justify-content: center;
  gap: 22px;
  flex-wrap: wrap;
}

/* ── Recipe Nº 002 ───────────────────────────────────────── */
.recipe-card {
  max-width: 860px;
  margin: 0 auto;
  box-shadow: 0 10px 26px rgba(80, 60, 30, 0.13);
  transform: rotate(0.5deg);
  padding: 46px 56px 50px;
}
.recipe-head {
  display: flex;
  align-items: baseline;
  gap: 12px;
  flex-wrap: wrap;
  border-bottom: 1.5px solid var(--box-line);
  padding-bottom: 16px;
  margin-bottom: 26px;
}
.recipe-title {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: clamp(24px, 2.8vw, 34px);
  letter-spacing: -0.02em;
  margin: 0;
}
.recipe-meta { margin-left: auto; font-size: 12.5px; color: var(--box-ink-soft); }
.recipe-grid { display: grid; grid-template-columns: 1fr 1.4fr; gap: 44px; }
.col-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.9px;
  text-transform: uppercase;
  color: var(--box-ink-soft);
  margin-bottom: 16px;
}
.ingredients {
  display: flex;
  flex-direction: column;
  gap: 12px;
  font-size: 14.5px;
  line-height: 1.5;
}
.ing { display: flex; gap: 10px; }
.ing-box {
  width: 15px;
  height: 15px;
  border: 1.5px solid rgba(36, 56, 156, 0.5);
  border-radius: 3px;
  flex: none;
  margin-top: 2px;
}
.method { display: flex; flex-direction: column; gap: 18px; }
.step { display: flex; gap: 14px; }
.step-no {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: 20px;
  color: rgba(36, 56, 156, 0.45);
  flex: none;
  width: 26px;
}
.step p { margin: 0; font-size: 14.5px; line-height: 1.65; text-wrap: pretty; }
.spine-note {
  position: absolute;
  left: -14px;
  bottom: 34px;
  transform: rotate(-90deg) translateY(-100%);
  transform-origin: left bottom;
  font-size: 12px;
  color: var(--box-ink-faint);
  white-space: nowrap;
}

/* ── Feature cards ───────────────────────────────────────── */
.cards-head { display: flex; align-items: baseline; gap: 14px; margin-bottom: 40px; }
.flip-hint { font-size: 12.5px; color: var(--box-ink-faint); }
.cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 26px 20px;
  align-items: start;
}
.feature { position: relative; padding-top: 27px; }
.feature-tab {
  position: absolute;
  top: 0;
  left: 18px;
  padding: 5px 14px 22px;
  border-radius: 8px 8px 0 0;
  background: var(--box-tab);
  border: 1px solid var(--box-line);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: var(--box-ink-soft);
  z-index: 0;
}
.feature-card {
  box-shadow: var(--box-shadow-md);
  padding: 20px 22px 22px;
  z-index: 1;
  transition: transform 0.15s, box-shadow 0.15s;
}
.feature-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 22px rgba(80, 60, 30, 0.16);
}
.feature-head { display: flex; align-items: center; gap: 9px; margin-bottom: 9px; }
.feature-icon { font-size: 21px; color: var(--box-primary); flex: none; }
.feature-title { font-family: var(--font-display); font-weight: 700; font-size: 16px; }
.feature-body {
  font-size: 13.5px;
  line-height: 1.95;
  color: var(--box-ink-soft);
  margin: 0;
  text-wrap: pretty;
}

/* ── Taped-in phone ──────────────────────────────────────── */
.pocket-grid {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: 56px;
  align-items: center;
}
.pocket-title { margin: 0 0 18px; max-width: 420px; }
.pocket-lede {
  font-size: 15.5px;
  line-height: 1.85;
  color: var(--box-ink-soft);
  margin: 0 0 24px;
  max-width: 440px;
  text-wrap: pretty;
}
.pocket-points {
  display: flex;
  flex-direction: column;
  gap: 10px;
  font-size: 13.5px;
  color: var(--box-ink-soft);
}
.pocket-points span { display: flex; align-items: center; gap: 9px; }
.point-icon { font-size: 17px; color: var(--box-accent); flex: none; }

/* ── Rescue strip ────────────────────────────────────────── */
.strip {
  display: grid;
  grid-template-columns: 1fr auto 1fr auto 1fr;
  gap: 18px;
  align-items: center;
}
.photo {
  position: relative;
  margin: 0;
  background: var(--box-card);
  border: 1px solid var(--box-edge);
  border-radius: 6px;
  box-shadow: var(--box-shadow-md);
  padding: 12px 12px 10px;
}
.photo img {
  display: block;
  width: 100%;
  height: 360px;
  object-fit: cover;
  object-position: top;
  border-radius: 3px;
  border: 1px solid rgba(120, 90, 50, 0.12);
}
.photo figcaption {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 2px 2px;
  font-size: 12.5px;
  color: var(--box-ink-soft);
}
.step-tag {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 999px;
  border: 1.5px solid rgba(36, 56, 156, 0.5);
  color: var(--box-primary);
  font-family: var(--font-display);
  font-weight: 800;
  font-size: 11px;
  flex: none;
}
.strip-arrow {
  font-size: 26px;
  color: var(--box-margin-note);
  font-family: var(--font-display);
  font-weight: 800;
}
.strip-note { text-align: right; margin-top: 12px; transform: rotate(-1deg); font-size: 12.5px; }

/* ── Price card ──────────────────────────────────────────── */
.price-card {
  max-width: 640px;
  margin: 0 auto;
  box-shadow: 0 14px 34px rgba(80, 60, 30, 0.16);
  transform: rotate(-0.6deg);
  padding: 46px 54px 44px;
}
.onetime {
  position: absolute;
  right: 34px;
  top: -18px;
  transform: rotate(9deg);
  border: 3px double #b40050;
  border-radius: 8px;
  padding: 8px 16px;
  font-family: ui-monospace, 'SF Mono', Menlo, monospace;
  font-size: 12px;
  letter-spacing: 2.5px;
  color: #b40050;
  text-transform: uppercase;
  background: var(--box-card);
  box-shadow: 0 2px 6px rgba(80, 60, 30, 0.1);
}
.price-no { margin-bottom: 14px; }
.price-row { display: flex; align-items: baseline; gap: 12px; margin-bottom: 6px; }
.price {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: 56px;
  letter-spacing: -0.02em;
}
.price-note { font-size: 14.5px; color: var(--box-ink-soft); }
.price-rule { height: 1.5px; background: var(--box-line); margin: 20px 0 22px; }
.price-checks { display: flex; flex-direction: column; gap: 12px; font-size: 14.5px; }
.price-check { gap: 11px; }
.price-check .check-icon { font-size: 18px; }
.price-marginalia {
  text-align: right;
  margin-top: 14px;
  transform: rotate(-1.5deg);
  font-size: 12.5px;
}
.price-fine { text-align: center; font-size: 12px; color: var(--box-ink-soft); margin-top: 12px; }

/* ── Keep it ─────────────────────────────────────────────── */
.yours { max-width: 760px; margin: 0 auto; text-align: center; }
.yours-title { font-size: clamp(26px, 3.2vw, 38px); line-height: 1.15; margin: 0 0 16px; }
.yours-lede {
  font-size: 15.5px;
  line-height: 1.85;
  color: var(--box-ink-soft);
  margin: 0 auto 36px;
  max-width: 520px;
  text-wrap: pretty;
}
.envelope { position: relative; max-width: 560px; margin: 0 auto; height: 190px; }
.slip {
  position: absolute;
  left: 50%;
  width: 150px;
  padding: 14px 12px 40px;
  background: var(--box-card);
  border: 1px solid var(--box-edge);
  border-radius: 6px;
  box-shadow: 0 4px 10px rgba(80, 60, 30, 0.12);
  font-size: 12.5px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
  justify-content: center;
}
.slip-icon { font-size: 18px; color: var(--box-primary); }
.envelope-front {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 120px;
  background: var(--box-tab-alt);
  border: 1px solid rgba(120, 90, 50, 0.3);
  border-radius: 10px 10px 12px 12px;
  box-shadow: 0 8px 20px rgba(80, 60, 30, 0.15);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding-bottom: 18px;
}
.envelope-front span {
  font-size: 11px;
  letter-spacing: 0.9px;
  text-transform: uppercase;
  color: var(--box-ink-faint);
}

/* ── Small screens: the box folds ────────────────────────── */
@media (max-width: 900px) {
  .cards-grid { grid-template-columns: repeat(2, 1fr); }
  .pocket-grid { grid-template-columns: 1fr; gap: 48px; justify-items: center; }
  .pocket-grid > div:first-child { text-align: center; }
  .pocket-title, .pocket-lede { max-width: 520px; margin-left: auto; margin-right: auto; }
  .pocket-points { align-items: center; }
}
@media (max-width: 720px) {
  .scatter { display: none; }
  .strip { grid-template-columns: 1fr; }
  .strip-arrow { transform: rotate(90deg); justify-self: center; }
  .photo img { height: 300px; }
  .hero-card { padding: 44px 30px 40px; }
  .hero-marginalia { display: none; }
  .recipe-card { padding: 38px 28px 42px; }
  .recipe-grid { grid-template-columns: 1fr; gap: 32px; }
  .spine-note { display: none; }
  .price-card { padding: 40px 28px 38px; }
}
@media (max-width: 600px) {
  .cards-grid { grid-template-columns: 1fr; }
}
</style>
