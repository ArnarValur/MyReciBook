// Missing keys in any locale fall back to the English source instead of
// printing raw key paths — is/sv lag behind en.json on purpose (human-owned),
// and the translation sticker in the layout tells the reader English governs.
export default defineI18nConfig(() => ({
  fallbackLocale: 'en',
}))
