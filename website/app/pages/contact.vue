<script setup lang="ts">
// Address is a placeholder until the myrecibook.com mailbox is verified.
const { t } = useI18n()
useSeoMeta({
  title: t('contact.seo.title'),
  description: t('contact.seo.description'),
})

// No backend yet. Until the Firebase function (with captcha) is in place the
// form composes a mail in the visitor's own client — nothing leaves this page
// on its own, so there is nothing to spam. Swap `send()` for the POST when the
// endpoint exists; the markup and validation stay as they are.
const form = reactive({ name: '', email: '', message: '' })
const touched = ref(false)
const state = ref<'idle' | 'sending' | 'sent' | 'failed'>('idle')

// Spam traps. `company` is hidden from sighted users by CSS and from screen
// readers by aria-hidden/tabindex — only a script that reads the markup fills
// it. `loadedAt` catches the other tell: a form posted back faster than anyone
// could type it. Both are re-checked on the server, which is where it counts;
// a bot posting straight to the endpoint never runs any of this.
const company = ref('')
const loadedAt = ref(0)
onMounted(() => { loadedAt.value = Date.now() })

const emailLooksReal = computed(() => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim()))
const ready = computed(() =>
  form.name.trim().length > 1 && emailLooksReal.value && form.message.trim().length > 4,
)

const endpoint = useRuntimeConfig().public.contactEndpoint

async function send() {
  touched.value = true
  if (!ready.value || state.value === 'sending') return
  state.value = 'sending'
  try {
    await $fetch(endpoint, {
      method: 'POST',
      body: {
        name: form.name.trim(),
        email: form.email.trim(),
        message: form.message.trim(),
        company: company.value,
        elapsedMs: loadedAt.value ? Date.now() - loadedAt.value : 0,
      },
    })
    state.value = 'sent'
    form.name = ''
    form.email = ''
    form.message = ''
    touched.value = false
  }
  catch {
    // Never leave someone's words stranded — the address is right there.
    state.value = 'failed'
  }
}
</script>

<template>
  <section class="section">
    <div class="doc-card paper ruled contact-card">
      <CardTape style="left: 26px; top: -14px; width: 104px; height: 28px; transform: rotate(-4deg)" />
      <CardTape style="right: 26px; top: -14px; width: 104px; height: 28px; transform: rotate(3deg)" />
      <h1>{{ $t('contact.title') }}</h1>
      <p class="doc-meta">{{ $t('contact.meta') }}</p>
      <p v-html="$t('contact.lede')" />

      <p v-if="state === 'sent'" class="sent-note">
        {{ $t('contact.sent') }}
      </p>

      <form v-else class="note-form" novalidate @submit.prevent="send">
        <label class="field">
          <span class="field-label">{{ $t('contact.fieldName') }}</span>
          <input v-model="form.name" type="text" autocomplete="name" class="field-input">
        </label>

        <label class="field">
          <span class="field-label">{{ $t('contact.fieldEmail') }}</span>
          <input v-model="form.email" type="email" autocomplete="email" class="field-input">
        </label>

        <label class="field">
          <span class="field-label">{{ $t('contact.fieldMessage') }}</span>
          <textarea v-model="form.message" rows="5" class="field-input field-area" />
        </label>

        <!-- Bots fill this; people never see it. Do not add a visible label. -->
        <div class="trap" aria-hidden="true">
          <input v-model="company" type="text" tabindex="-1" autocomplete="off">
        </div>

        <p v-if="touched && !ready" class="field-note">
          {{ $t('contact.invalid') }}
        </p>
        <p v-else-if="state === 'failed'" class="field-note">
          {{ $t('contact.failed') }}
        </p>

        <button type="submit" class="cta contact-cta" :disabled="state === 'sending'">
          <UIcon name="i-material-symbols:send-rounded" class="cta-icon" />
          {{ state === 'sending' ? $t('contact.sending') : $t('contact.send') }}
        </button>
      </form>

      <p v-if="state !== 'sent'" class="doc-meta contact-fallback">
        <i18n-t keypath="contact.fallback">
          <template #email>
            <a href="mailto:support@myrecibook.com">support@myrecibook.com</a>
          </template>
        </i18n-t>
      </p>
    </div>
  </section>
</template>

<style scoped>
.contact-card { text-align: center; }

.note-form {
  max-width: 440px;
  margin: 26px auto 0;
  text-align: left;
}

.field { display: block; margin-bottom: 18px; }
.field-label {
  display: block;
  font-size: 12.5px;
  font-weight: 600;
  letter-spacing: 0.02em;
  color: var(--box-ink-faint);
  margin-bottom: 4px;
}
/* A boxed field on its own stock — the page's ruling running behind typed
   text made it hard to read, so the field paints over it. */
.field-input {
  display: block;
  width: 100%;
  background: rgba(255, 255, 255, 0.92);
  border: 1.5px solid var(--box-edge);
  border-radius: 12px;
  padding: 10px 13px;
  font: inherit;
  font-size: 14.5px;
  line-height: 1.6;
  color: var(--box-ink);
  outline: none;
  box-shadow: inset 0 1px 2px rgba(80, 60, 30, 0.06);
  transition: border-color 0.15s, box-shadow 0.15s;
}
.field-input:focus {
  border-color: var(--box-primary);
  box-shadow: 0 0 0 3px rgba(36, 56, 156, 0.14);
}
.field-area { resize: vertical; min-height: 110px; }

/* Off-screen rather than display:none — some bots skip undisplayed fields */
.trap {
  position: absolute;
  left: -9999px;
  width: 1px;
  height: 1px;
  overflow: hidden;
}

.field-note {
  font-size: 12.5px;
  color: var(--box-stamp-red);
  margin: 0 0 12px;
}

.contact-cta { margin-top: 6px; width: 100%; }
.contact-cta[disabled] { opacity: 0.6; pointer-events: none; }
.sent-note {
  margin: 26px 0 0;
  font-size: 14.5px;
  font-weight: 600;
  color: var(--box-accent);
}
.contact-fallback { margin: 20px 0 0; }
.contact-fallback a { color: var(--box-accent); font-weight: 600; }
</style>
