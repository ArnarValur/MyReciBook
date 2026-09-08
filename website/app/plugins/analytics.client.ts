// Loads Google Analytics — and only after the visitor has agreed.
//
// While the answer is unset or "no" the tag script is never fetched, so Google
// gets nothing at all. Withdrawing afterwards reloads the page: Google's tag
// cannot be unloaded once running, so starting over is the only honest stop.
export default defineNuxtPlugin(() => {
  const { enabled, choice, read } = useCookieConsent()
  const measurementId = useRuntimeConfig().public.gaMeasurementId as string

  read()
  if (!enabled.value) return

  let injected = false

  watch(choice, (value) => {
    if (value !== 'granted' || injected) return
    injected = true

    const script = document.createElement('script')
    script.async = true
    script.src = `https://www.googletagmanager.com/gtag/js?id=${measurementId}`
    document.head.appendChild(script)

    const w = window as unknown as { dataLayer: unknown[] }
    w.dataLayer = w.dataLayer || []
    // This MUST push the `arguments` object, not a real array. Google's tag reads
    // the queue expecting arguments objects and silently ignores plain arrays —
    // the script loads, nothing errors, and no hit is ever sent. Hence the odd
    // shape here instead of a tidy rest parameter.
    const gtag = function () {
      // eslint-disable-next-line prefer-rest-params
      w.dataLayer.push(arguments)
    } as (...args: unknown[]) => void
    // Google's basic consent mode. We only get here after a yes, so the default
    // block is immediately followed by the grant — but stating both is what stops
    // the tag deferring its first hits, and it keeps advertising storage denied
    // for good, because we run no ads.
    gtag('consent', 'default', {
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied',
    })
    gtag('consent', 'update', { analytics_storage: 'granted' })

    gtag('js', new Date())
    gtag('config', measurementId)

    // Every route change is its own page view — the site is a single page app
    // once loaded, so Google would otherwise only ever see the first page.
    const router = useRouter()
    router.afterEach((to) => {
      gtag('event', 'page_view', {
        page_path: to.fullPath,
        page_location: window.location.origin + to.fullPath,
        page_title: document.title,
      })
    })
  }, { immediate: true })
})
