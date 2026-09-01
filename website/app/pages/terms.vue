<script setup lang="ts">
// DRAFT until Arnar approves the wording — the stamp says so on the page.
const { t } = useI18n()
useSeoMeta({
  title: t('terms.seo.title'),
  description: t('terms.seo.description'),
})
</script>

<template>
  <section class="section">
    <div class="doc-card paper ruled">
      <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(1deg)" />
      <span class="doc-draft">{{ $t('terms.stamp') }}</span>
      <h1>{{ $t('terms.title') }}</h1>

      <h2>{{ $t('terms.dealTitle') }}</h2>
      <p>{{ $t('terms.dealBody') }}</p>

      <h2>{{ $t('terms.rescuesTitle') }}</h2>
      <p>{{ $t('terms.rescuesBody') }}</p>

      <h2>{{ $t('terms.contentTitle') }}</h2>
      <p>{{ $t('terms.contentBody') }}</p>

      <h2>{{ $t('terms.takedownTitle') }}</h2>
      <p>
        <i18n-t keypath="terms.takedownBody">
          <template #email>
            <a href="mailto:support@myrecibook.com">support@myrecibook.com</a>
          </template>
        </i18n-t>
      </p>

      <h2>{{ $t('terms.imperfectTitle') }}</h2>
      <p>{{ $t('terms.imperfectBody') }}</p>
      <p>{{ $t('terms.personBody') }}</p>
    </div>
  </section>
</template>
