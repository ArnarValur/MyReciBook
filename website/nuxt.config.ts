// https://nuxt.com/docs/api/configuration/nuxt-config

// Every language the site knows. Locale files live in i18n/locales/.
const allLocales = [
  { code: 'en', language: 'en', name: 'English', file: 'en.json' },
  { code: 'is', language: 'is', name: 'Íslenska', file: 'is.json' },
  { code: 'sv', language: 'sv', name: 'Svenska', file: 'sv.json' },
  { code: 'nb', language: 'nb', name: 'Norsk', file: 'nb.json' },
  { code: 'da', language: 'da', name: 'Dansk', file: 'da.json' },
  { code: 'fi', language: 'fi', name: 'Suomi', file: 'fi.json' },
  { code: 'fo', language: 'fo', name: 'Føroyskt', file: 'fo.json' },
]

// Only COMPLETE, reviewed languages are published (i18n track D9; paused by
// market Decision 2, 2026-09-01). Until then the site is English only: one
// address per page, and no half-translated copies for Google to file as
// duplicates of the English page (Search Console, 2026-09-16). Add a code here
// the day its language is finished — and drop it from the locale redirect in
// nginx.conf the same day. The locale files and the layout wiring are untouched.
const liveLocales = ['en']

export default defineNuxtConfig({
  compatibilityDate: '2026-08-28',
  devtools: { enabled: true },
  modules: ['@nuxt/ui', '@nuxtjs/seo', '@nuxtjs/i18n'],
  css: ['~/assets/css/main.css'],

  // i18n foundation — English only until a second language is fully translated
  // (mirrors the app: no visible switcher before one language is done).
  // With prefix_except_default and a single live locale, routes and sitemap
  // carry no language prefix.
  i18n: {
    defaultLocale: 'en',
    // A few messages carry inline <strong>/<br> — our own locale files, not user input
    compilation: { strictMessage: false },
    strategy: 'prefix_except_default',
    baseUrl: 'https://myrecibook.com',
    detectBrowserLanguage: false,
    locales: allLocales.filter((l) => liveLocales.includes(l.code)),
  },

  // SEO foundation — sitemap, robots, canonicals and schema.org all key off this
  // The canonical address is https://myrecibook.com/path — no trailing slash.
  // nginx.conf 301s every other spelling (www, /path/, /index.html) onto it.
  site: {
    url: 'https://myrecibook.com',
    trailingSlash: false,
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
      // Google Analytics 4, web stream "MyReciBook Website" on the myrecibook-prod
      // property — the same property the Android app reports into. The id is public
      // by design (it ships in the page source). Set it empty to switch analytics
      // and the consent note off completely, e.g. for a staging build.
      gaMeasurementId: 'G-M301GKVM58',
    },
  },

  // One flat /sitemap.xml instead of a sitemap index split per language —
  // with a single live locale the index only adds a hop (/sitemap.xml was a
  // meta-refresh shell pointing at /sitemap_index.xml). Alternates (hreflang)
  // still ride each entry, so this can stay when more languages go live.
  sitemap: { sitemaps: false },

  // OG images off until we design one (index-card style, later)
  ogImage: { enabled: false },
})
