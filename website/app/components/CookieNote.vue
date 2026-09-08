<script setup lang="ts">
// The consent note. Shows once, at the bottom, only when the visitor has not
// answered yet. Same taped-on-note idiom as the translation sticker in the layout.
const { showBanner, set } = useCookieConsent()
const localePath = useLocalePath()
</script>

<template>
  <ClientOnly>
    <Transition name="note">
      <div v-if="showBanner" class="cookie-note" role="dialog" aria-live="polite">
        <p class="cookie-text">
          {{ $t('cookies.body') }}
          <NuxtLink :to="localePath('/privacy')" class="cookie-link">{{ $t('cookies.more') }}</NuxtLink>
        </p>
        <div class="cookie-actions">
          <UButton size="sm" color="neutral" variant="ghost" class="cookie-no" @click="set('denied')">
            {{ $t('cookies.decline') }}
          </UButton>
          <UButton size="sm" class="cookie-yes" @click="set('granted')">
            {{ $t('cookies.accept') }}
          </UButton>
        </div>
      </div>
    </Transition>
  </ClientOnly>
</template>

<style scoped>
.cookie-note {
  position: fixed;
  left: 50%;
  bottom: 18px;
  z-index: 50;
  transform: translateX(-50%) rotate(-0.3deg);
  width: min(680px, calc(100vw - 32px));
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
  padding: 14px 18px;
  background: var(--box-tab-alt);
  border: 1px dashed var(--box-line);
  border-radius: 12px;
  box-shadow: var(--box-shadow-md);
}
.cookie-text {
  flex: 1;
  min-width: 240px;
  margin: 0;
  font-size: 13px;
  line-height: 1.55;
  color: var(--box-ink-soft);
}
.cookie-link { color: var(--box-primary); text-decoration: underline; }
.dark .cookie-link { color: var(--box-accent); }
.cookie-actions { display: flex; gap: 8px; margin-left: auto; }
.cookie-no { color: var(--box-ink-faint); }

.note-enter-active { transition: opacity 0.35s ease, transform 0.35s ease; }
.note-leave-active { transition: opacity 0.2s ease; }
.note-enter-from { opacity: 0; transform: translateX(-50%) translateY(12px) rotate(-0.3deg); }
.note-leave-to { opacity: 0; }

@media (max-width: 620px) {
  .cookie-note { bottom: 12px; padding: 14px 16px; }
  .cookie-actions { width: 100%; margin-left: 0; justify-content: flex-end; }
}
</style>
