<script setup lang="ts">
// The box has no card at this address.
import type { NuxtError } from '#app'
defineProps<{ error: NuxtError }>()
useSeoMeta({ title: 'Not in the box — MyReciBook' })
</script>

<template>
  <NuxtLayout>
    <section class="section">
      <div class="doc-card paper ruled err-card">
        <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(-1.5deg)" />
        <span class="card-no">RECIPE Nº {{ error.statusCode }}</span>
        <h1>Not in the box.</h1>
        <p>
          This card must have been lent to a neighbor and never returned.
          The rest of the box is where you left it.
        </p>
        <NuxtLink to="/" class="cta err-cta">
          <UIcon name="i-material-symbols:menu-book-rounded" class="cta-icon" />Back to the box
        </NuxtLink>
      </div>
    </section>
  </NuxtLayout>
</template>

<style scoped>
.err-card { text-align: center; }
.err-cta { margin-top: 16px; }
</style>
