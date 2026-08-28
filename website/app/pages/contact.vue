<script setup lang="ts">
// Address is a placeholder until the myrecibook.com mailbox is verified.
useSeoMeta({
  title: 'Contact — MyReciBook',
  description:
    'Found a bug, lost a recipe, or want to tell us what belongs in the box next? Write — a person reads it.',
})
</script>

<template>
  <section class="section">
    <div class="doc-card paper ruled contact-card">
      <CardTape style="left: 50%; top: -13px; width: 120px; height: 28px; transform: translateX(-50%) rotate(-1deg)" />
      <h1>Contact</h1>
      <p class="doc-meta">From the kitchen of · Merkurial-Studio</p>
      <p>
        Found a bug, lost a recipe, or want to tell us what belongs in the box
        next? Write — a person reads it.
      </p>
      <a href="mailto:support@myrecibook.com" class="cta contact-cta">
        <UIcon name="i-material-symbols:send-rounded" class="cta-icon" />support@myrecibook.com
      </a>
    </div>
  </section>
</template>

<style scoped>
.contact-card { text-align: center; }
.contact-cta { margin-top: 16px; }
</style>
