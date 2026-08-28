<script setup lang="ts">
// Site-wide structured data — the schema Google reads for app queries.
// No price/rating yet: nothing invented, added when decided/real.
useSchemaOrg([
  defineWebSite({ name: 'MyReciBook' }),
  defineSoftwareApp({
    name: 'MyReciBook',
    operatingSystem: 'Android',
    applicationCategory: 'LifestyleApplication',
    description:
      'Turns recipe screenshots, links and handwritten cards into a cookbook you own — plain files on your phone. No subscription, no account.',
  }),
])
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
