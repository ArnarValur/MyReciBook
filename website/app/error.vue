<script setup lang="ts">
// The box has no card at this address.
import type { NuxtError } from '#app'
defineProps<{ error: NuxtError }>()
const { t } = useI18n()
useSeoMeta({ title: t('error.seo.title') })
</script>

<template>
  <NuxtLayout>
    <section class="section">
      <div class="doc-card paper ruled err-card">
        <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(-1.5deg)" />
        <span class="card-no">{{ $t('error.cardNo', { code: error.statusCode }) }}</span>
        <h1>{{ $t('error.title') }}</h1>
        <p>{{ $t('error.body') }}</p>
        <NuxtLink to="/" class="cta err-cta">
          <UIcon name="i-material-symbols:menu-book-rounded" class="cta-icon" />{{ $t('error.cta') }}
        </NuxtLink>
      </div>
    </section>
  </NuxtLayout>
</template>

<style scoped>
.err-card { text-align: center; }
.err-cta { margin-top: 16px; }
</style>
