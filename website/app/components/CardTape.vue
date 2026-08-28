<template>
  <div class="tape" aria-hidden="true" />
</template>

<style scoped>
/* A strip of translucent tape — position it from the parent via style. */
.tape {
  position: absolute;
  width: 104px;
  height: 30px;
  background: rgba(255, 255, 255, 0.5);
  border-left: 1px dashed var(--box-line);
  border-right: 1px dashed var(--box-line);
  box-shadow: 0 1px 3px rgba(80, 60, 30, 0.12);
}
</style>
