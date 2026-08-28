// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2026-08-28',
  devtools: { enabled: true },
  modules: ['@nuxt/ui'],
  css: ['~/assets/css/main.css'],
  app: {
    head: {
      title: 'MyReciBook — Rescue the recipes buried in your camera roll',
      htmlAttrs: { lang: 'en' },
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        {
          name: 'description',
          content:
            'MyReciBook turns the recipe screenshots in your camera roll into a cookbook you own. Pay once. Cook forever. Android.',
        },
      ],
    },
  },
})
