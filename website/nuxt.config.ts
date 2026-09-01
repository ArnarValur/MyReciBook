// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2026-08-28',
  devtools: { enabled: true },
  modules: ['@nuxt/ui', '@nuxtjs/seo', '@nuxtjs/i18n'],
  css: ['~/assets/css/main.css'],

  // i18n foundation — English only until a second language is fully translated
  // (mirrors the app: no visible switcher before one language is done).
  // Locale files live in i18n/locales/. With prefix_except_default and a single
  // locale, routes and sitemap are unchanged.
  i18n: {
    defaultLocale: 'en',
    // A few messages carry inline <strong>/<br> — our own locale files, not user input
    compilation: { strictMessage: false },
    strategy: 'prefix_except_default',
    baseUrl: 'https://myrecibook.com',
    detectBrowserLanguage: false,
    locales: [
      { code: 'en', language: 'en', name: 'English', file: 'en.json' },
      { code: 'is', language: 'is', name: 'Íslenska', file: 'is.json' },
      { code: 'sv', language: 'sv', name: 'Svenska', file: 'sv.json' },
      { code: 'nb', language: 'nb', name: 'Norsk', file: 'nb.json' },
      { code: 'da', language: 'da', name: 'Dansk', file: 'da.json' },
      { code: 'fi', language: 'fi', name: 'Suomi', file: 'fi.json' },
      { code: 'fo', language: 'fo', name: 'Føroyskt', file: 'fo.json' },
    ],
  },

  // SEO foundation — sitemap, robots, canonicals and schema.org all key off this
  site: {
    url: 'https://myrecibook.com',
    name: 'MyReciBook',
    description:
      'MyReciBook turns the recipe screenshots in your camera roll into a cookbook you own. Pay once. Cook forever. Android.',
    defaultLocale: 'en',
  },

  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      meta: [{ name: 'theme-color', content: '#efe4cd' }],
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
        { rel: 'apple-touch-icon', href: '/icon-192.png' },
      ],
    },
  },

  // Static site: every route prerendered at build, crawlers get full HTML
  nitro: {
    prerender: {
      crawlLinks: true,
      routes: ['/'],
    },
  },

  // Where the contact form posts. The extraction proxy carries the route —
  // one Cloud Run service, one Secret Manager. Overridable at build time with
  // NUXT_PUBLIC_CONTACT_ENDPOINT.
  runtimeConfig: {
    public: {
      contactEndpoint:
        'https://myrecibook-proxy-dolshlji5a-ew.a.run.app/contact',
    },
  },

  // OG images off until we design one (index-card style, later)
  ogImage: { enabled: false },
})
