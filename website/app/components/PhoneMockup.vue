<template>
  <div class="phone-wrap">
    <CardTape style="left: -24px; top: -14px; width: 110px; transform: rotate(-35deg); z-index: 2" />
    <CardTape style="right: -24px; bottom: -10px; width: 110px; transform: rotate(-35deg); z-index: 2" />

    <div class="frame">
      <div class="screen">
        <div class="topbar">
          <span class="wordmark">MyReciBook</span>
          <UIcon name="i-material-symbols:search-rounded" class="muted-icon" />
        </div>
        <div class="chips">
          <span class="chip chip-active">All · 34</span>
          <span class="chip">Dinner</span>
          <span class="chip">Baking</span>
        </div>
        <div class="grid">
          <div class="cell">
            <div class="cover" style="background: var(--cover-terracotta)">
              <UIcon name="i-material-symbols:favorite-rounded" class="heart" />
            </div>
            <div class="cell-title">Nana's meatballs</div>
            <div class="cell-meta">45 min · Serves 4</div>
          </div>
          <div class="cell">
            <div class="cover" style="background: var(--cover-teal)" />
            <div class="cell-title">Lemon orzo soup</div>
            <div class="cell-meta">25 min · Serves 4</div>
          </div>
          <div class="cell">
            <div class="cover" style="background: var(--cover-plum)" />
            <div class="cell-title">Plum galette</div>
            <div class="cell-meta">1,5 hr · 4–6 servings</div>
          </div>
          <div class="cell">
            <div class="cover" style="background: var(--cover-olive)" />
            <div class="cell-title">Green shakshuka</div>
            <div class="cell-meta">30 min · Serves 2</div>
          </div>
        </div>
        <div class="navpill">
          <UIcon name="i-material-symbols:menu-book-rounded" class="nav-icon nav-active" />
          <UIcon name="i-material-symbols:checklist-rounded" class="nav-icon" />
          <span class="fab"><UIcon name="i-material-symbols:add-rounded" /></span>
          <UIcon name="i-material-symbols:restaurant-rounded" class="nav-icon" />
          <UIcon name="i-material-symbols:settings-rounded" class="nav-icon" />
        </div>
      </div>
    </div>

    <div class="marginalia" aria-hidden="true">covers pick their own color →</div>
  </div>
</template>

<style scoped>
/* The app's own light theme, scoped to the mockup — the paper page
   around it never changes, so neither does the phone. */
.phone-wrap {
  --p-primary: #24389c;
  --p-primary-container: #3f51b5;
  --p-scaffold: #faf8f0;
  --p-secondary-container: #abb7ff;
  --p-on-secondary-container: #394687;
  --p-surface-container-high: #e8e8ea;
  --p-on-surface-variant: #454652;
  --p-glass-fill: rgba(255, 255, 255, 0.55);
  --p-glass-border: rgba(0, 0, 0, 0.08);
  position: relative;
  justify-self: center;
}
.frame {
  width: 290px;
  height: 600px;
  border-radius: 36px;
  background: #1a1c1e;
  padding: 9px;
  box-shadow: 0 20px 44px rgba(80, 60, 30, 0.28);
  transform: rotate(1.4deg);
}
.screen {
  width: 100%;
  height: 100%;
  border-radius: 28px;
  background: var(--p-scaffold);
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
}
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 16px 10px;
}
.wordmark {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: 17px;
  color: var(--p-primary);
}
.muted-icon { font-size: 19px; color: var(--p-on-surface-variant); }
.chips { display: flex; gap: 6px; padding: 0 16px 12px; }
.chip {
  padding: 5px 13px;
  border-radius: 999px;
  background: var(--p-surface-container-high);
  color: var(--p-on-surface-variant);
  font-size: 11px;
  font-weight: 500;
}
.chip-active {
  background: var(--p-secondary-container);
  color: var(--p-on-secondary-container);
  font-weight: 600;
}
.grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  padding: 0 14px;
  flex: 1;
}
.cell { display: flex; flex-direction: column; gap: 6px; }
.cover { height: 110px; border-radius: 12px; position: relative; }
.heart { position: absolute; top: 7px; right: 7px; font-size: 15px; color: #ffb1c1; }
.cell-title {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: 12.5px;
  line-height: 1.25;
  color: #1a1c1e;
}
.cell-meta { font-size: 10.5px; color: var(--p-on-surface-variant); }
.navpill {
  position: absolute;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 18px;
  border-radius: 999px;
  background: var(--p-glass-fill);
  backdrop-filter: blur(20px);
  border: 1px solid var(--p-glass-border);
  box-shadow: 0 4px 10px rgba(36, 56, 156, 0.1);
}
.nav-icon { font-size: 20px; color: var(--p-on-surface-variant); }
.nav-active { color: var(--p-primary); }
.fab {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 999px;
  background: linear-gradient(135deg, var(--p-primary-container), var(--p-primary));
  color: #fff;
  font-size: 21px;
  box-shadow: 0 4px 12px rgba(36, 56, 156, 0.35);
}
.marginalia {
  position: absolute;
  left: -120px;
  top: 120px;
  font-style: italic;
  font-size: 12.5px;
  color: rgba(36, 56, 156, 0.7);
  max-width: 100px;
  line-height: 1.45;
  transform: rotate(-4deg);
}
@media (max-width: 1023px) {
  .marginalia { display: none; }
}
</style>
