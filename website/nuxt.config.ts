// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2026-08-28',
  devtools: { enabled: true },
  modules: ['@nuxt/ui', '@nuxtjs/seo'],
  css: ['~/assets/css/main.css'],

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

  // OG images off until we design one (index-card style, later)
  ogImage: { enabled: false },
})
