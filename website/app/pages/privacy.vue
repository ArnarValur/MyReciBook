<script setup lang="ts">
// DRAFT until Arnar approves the wording — the stamp says so on the page.
// Facts sourced from the app: local-first storage, stateless extraction proxy,
// hashed purchase-token cap counter, crash reporting with keys and file paths stripped.
const { t } = useI18n()
useSeoMeta({
  title: t('privacy.seo.title'),
  description: t('privacy.seo.description'),
})

// The visitor can change their mind about being counted right here, on the page
// that explains what counting means.
const { enabled: consentEnabled, choice, read, set: setConsent } = useCookieConsent()
onMounted(read)
const consentStatus = computed(() =>
  choice.value === 'granted'
    ? t('privacy.websiteStatus.granted')
    : choice.value === 'denied'
      ? t('privacy.websiteStatus.denied')
      : t('privacy.websiteStatus.none'),
)
</script>

<template>
  <section class="section">
    <div class="doc-card paper ruled">
      <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(-1deg)" />
      <span class="doc-draft">{{ $t('privacy.stamp') }}</span>
      <h1>{{ $t('privacy.title') }}</h1>
      <p class="doc-meta">{{ $t('privacy.meta') }}</p>

      <h2>{{ $t('privacy.localTitle') }}</h2>
      <p v-html="$t('privacy.localBody')" />

      <h2>{{ $t('privacy.leavesTitle') }}</h2>
      <ul>
        <li v-html="$t('privacy.leaves.rescues')" />
        <li v-html="$t('privacy.leaves.counter')" />
        <li v-html="$t('privacy.leaves.barcodes')" />
        <li v-html="$t('privacy.leaves.crash')" />
        <li v-html="$t('privacy.leaves.cloud')" />
      </ul>

      <h2>{{ $t('privacy.neverTitle') }}</h2>
      <ul>
        <li>{{ $t('privacy.never.accounts') }}</li>
        <li>{{ $t('privacy.never.ads') }}</li>
        <li>{{ $t('privacy.never.storing') }}</li>
      </ul>

      <h2>{{ $t('privacy.websiteTitle') }}</h2>
      <p>{{ $t('privacy.websiteBody') }}</p>
      <ClientOnly>
        <p v-if="consentEnabled" class="consent-row">
          <span>{{ consentStatus }}</span>
          <UButton
            v-if="choice !== 'granted'"
            size="xs"
            variant="soft"
            @click="setConsent('granted')"
          >
            {{ $t('privacy.websiteOptIn') }}
          </UButton>
          <UButton
            v-else
            size="xs"
            color="neutral"
            variant="soft"
            @click="setConsent('denied')"
          >
            {{ $t('privacy.websiteOptOut') }}
          </UButton>
        </p>
      </ClientOnly>

      <h2>{{ $t('privacy.payTitle') }}</h2>
      <p>{{ $t('privacy.payBody') }}</p>

      <h2>{{ $t('privacy.questionsTitle') }}</h2>
      <p>
        <i18n-t keypath="privacy.questionsBody">
          <template #link>
            <NuxtLink to="/contact" style="color: var(--box-primary)">{{ $t('privacy.questionsLink') }}</NuxtLink>
          </template>
        </i18n-t>
      </p>
    </div>
  </section>
</template>

<style scoped>
.consent-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  font-size: 13.5px;
  color: var(--box-ink-faint);
}
</style>
