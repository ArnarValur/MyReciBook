<script setup lang="ts">
// The app's logo mark (open book + steam), tinted by currentColor.
withDefaults(defineProps<{ size?: number }>(), { size: 30 })
const maskId = useId() // the mark appears twice per page — keep mask ids unique
</script>

<template>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" :width="size" :height="size" aria-hidden="true">
    <defs>
      <mask :id="maskId">
        <rect width="108" height="108" fill="white" />
        <path d="M54 62 L54 76" stroke="black" stroke-width="2.5" stroke-linecap="round" fill="none" />
      </mask>
    </defs>
    <g :mask="`url(#${maskId})`">
      <path d="M54 60 C47 53 36 51 26 53 L26 72 C36 70 47 72 54 78 C61 72 72 70 82 72 L82 53 C72 51 61 53 54 60 Z" fill="currentColor" />
      <path d="M45 26 c-5 7 5 9 0 16" stroke="currentColor" stroke-width="6" stroke-linecap="round" fill="none" />
      <path d="M63 26 c-5 7 5 9 0 16" stroke="currentColor" stroke-width="6" stroke-linecap="round" fill="none" />
    </g>
  </svg>
</template>
