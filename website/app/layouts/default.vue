<script setup lang="ts">
const colorMode = useColorMode()
const isDark = computed({
  get: () => colorMode.value === 'dark',
  set: (v) => { colorMode.preference = v ? 'dark' : 'light' },
})

const { locale, locales, setLocale } = useI18n()
// English carries the UK flag by Arnar's choice; each new language adds its pair here
const localeFlags: Record<string, string> = {
  en: 'i-circle-flags:gb',
}
const localeItems = computed(() =>
  locales.value.map((l) => ({
    label: l.name,
    icon: localeFlags[l.code],
    onSelect: () => setLocale(l.code),
  })),
)
</script>

<template>
  <div class="box">
    <!-- ── Box-lid header: wordmark stamp + divider tabs ────── -->
    <header class="lid">
      <div class="lid-row">
        <NuxtLink to="/" class="brand">
          <LogoMark :size="30" />
          <span class="brand-name">MyReciBook</span>
        </NuxtLink>
        <span class="est">{{ $t('layout.est') }}</span>
        <nav class="tabs">
          <NuxtLink to="/#recipe" class="tab" style="transform: translateY(1px)">{{ $t('layout.tabRecipe') }}</NuxtLink>
          <NuxtLink to="/#cards" class="tab tab-alt" style="transform: translateY(3px)">{{ $t('layout.tabCards') }}</NuxtLink>
          <NuxtLink to="/#price" class="tab" style="transform: translateY(2px)">{{ $t('layout.tabPrice') }}</NuxtLink>
          <NuxtLink to="/#yours" class="tab tab-alt" style="transform: translateY(4px)">{{ $t('layout.tabYours') }}</NuxtLink>
        </nav>
        <div class="lid-actions">
          <UDropdownMenu :items="localeItems">
            <UButton
              :icon="localeFlags[locale]"
              color="neutral"
              variant="ghost"
              class="lamp"
              :aria-label="$t('layout.language')"
            />
          </UDropdownMenu>
          <UButton
            :icon="isDark ? 'i-material-symbols:light-mode-rounded' : 'i-material-symbols:dark-mode-rounded'"
            color="neutral"
            variant="ghost"
            class="lamp"
            :aria-label="$t('layout.lamp')"
            @click="isDark = !isDark"
          />
        </div>
      </div>
      <div class="lid-edge" />
    </header>

    <slot />

    <!-- ── Footer: bottom of the box ────────────────────────── -->
    <footer class="foot">
      <div class="lid-edge foot-edge" />
      <div class="foot-row">
        <span class="foot-brand">
          <LogoMark :size="22" />
          <span>MyReciBook</span>
        </span>
        <span class="foot-line">{{ $t('layout.footLine') }} <a href="https://merkurial-studio.com" class="foot-link">Merkurial-Studio.com</a> · <a href="https://avj.info" class="foot-link">avj.info</a></span>
        <nav class="foot-nav">
          <NuxtLink to="/privacy">{{ $t('layout.privacy') }}</NuxtLink>
          <NuxtLink to="/terms">{{ $t('layout.terms') }}</NuxtLink>
          <NuxtLink to="/contact">{{ $t('layout.contact') }}</NuxtLink>
        </nav>
      </div>
    </footer>
  </div>
</template>

<style scoped>
/* ── The box ─────────────────────────────────────────────── */
.box {
  min-height: 100vh;
  background: var(--box-kraft);
  background-image:
    radial-gradient(ellipse 600px 400px at 15% 8%, rgba(180, 140, 80, 0.06), transparent 60%),
    radial-gradient(ellipse 500px 500px at 85% 30%, rgba(180, 140, 80, 0.05), transparent 60%),
    radial-gradient(ellipse 700px 500px at 40% 80%, rgba(160, 120, 70, 0.05), transparent 60%),
    repeating-linear-gradient(0deg, transparent 0 3px, rgba(120, 90, 50, 0.012) 3px 4px),
    repeating-linear-gradient(90deg, transparent 0 3px, rgba(120, 90, 50, 0.012) 3px 4px);
  overflow-x: hidden;
  color: var(--box-ink);
  font-family: var(--font-sans);
}
.dark .box {
  background-image:
    radial-gradient(ellipse 600px 400px at 15% 8%, rgba(96, 110, 190, 0.09), transparent 60%),
    radial-gradient(ellipse 500px 500px at 85% 30%, rgba(96, 110, 190, 0.07), transparent 60%),
    radial-gradient(ellipse 700px 500px at 40% 80%, rgba(96, 110, 190, 0.07), transparent 60%);
}

/* ── Box-lid header ──────────────────────────────────────── */
.lid { max-width: 1040px; margin: 0 auto; padding: 34px 24px 0; }
.lid-row { display: flex; align-items: flex-end; gap: 16px; flex-wrap: wrap; }
.brand { display: flex; align-items: center; gap: 10px; color: var(--box-accent); }
.brand-name {
  font-family: var(--font-display);
  font-weight: 800;
  font-size: 22px;
  letter-spacing: -0.01em;
}
.est {
  font-size: 11px;
  letter-spacing: 0.9px;
  text-transform: uppercase;
  color: var(--box-ink-faint);
  padding-bottom: 4px;
}
.tabs { margin-left: auto; display: flex; gap: 6px; align-items: flex-end; }
.tab {
  display: block;
  padding: 8px 16px 10px;
  border-radius: 10px 10px 0 0;
  background: var(--box-tab);
  border: 1px solid var(--box-line);
  border-bottom: none;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.5px;
  color: var(--box-ink-soft);
}
.tab-alt { background: var(--box-tab-alt); }
.tab:hover { background: var(--box-tab-hover); color: var(--box-accent); }
.lid-edge { height: 1.5px; background: var(--box-line); }
.lid-actions { align-self: center; display: flex; align-items: center; gap: 2px; }
.lamp { color: var(--box-ink-soft); }

/* ── Footer ──────────────────────────────────────────────── */
.foot { max-width: 1040px; margin: 88px auto 0; padding: 0 24px 46px; }
.foot-edge { margin-bottom: 26px; }
.foot-row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.foot-brand {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--box-accent);
  font-family: var(--font-display);
  font-weight: 800;
  font-size: 16px;
}
.foot-line { font-size: 12.5px; color: var(--box-ink-faint); }
.foot-link { color: var(--box-ink-soft); }
.foot-link:hover { color: var(--box-primary); }
.foot-nav { margin-left: auto; display: flex; gap: 20px; font-size: 12.5px; }
.foot-nav a { color: var(--box-ink-soft); }
.foot-nav a:hover { color: var(--box-accent); }

@media (max-width: 720px) {
  /* Row 1: brand + est with flag + lamp pinned right; row 2: the four tabs,
     evenly spread, one line each — no wrapped pills, no lonely moon row */
  .lid-row { position: relative; padding-right: 84px; }
  .lid-actions { position: absolute; right: 0; top: 0; align-self: auto; }
  .tabs { width: 100%; margin-left: 0; gap: 5px; }
  .tab {
    flex: 1;
    text-align: center;
    white-space: nowrap;
    padding: 7px 8px 9px;
    font-size: 11.5px;
    letter-spacing: 0.3px;
  }
  .foot-row { flex-direction: column; align-items: center; text-align: center; gap: 10px; }
  .foot-nav { margin-left: 0; }
}
</style>
