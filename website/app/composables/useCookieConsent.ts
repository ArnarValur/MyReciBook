// Analytics consent for the website.
//
// Nothing loads until the visitor says yes. While the choice is unset or denied
// the Google tag script is never even fetched, so no cookie is set and no
// request reaches Google. The answer lives in this browser's localStorage only —
// no cookie of our own, no server, nothing to sync.
export type ConsentChoice = 'granted' | 'denied'

const STORAGE_KEY = 'mrb-analytics-consent'

export function useCookieConsent() {
  const config = useRuntimeConfig()

  // No measurement id in the build (local dev, or a deploy without it) means the
  // whole feature is off: no tag, no banner, nothing to consent to.
  const enabled = computed(() => Boolean(config.public.gaMeasurementId))

  const choice = useState<ConsentChoice | null>('analytics-consent', () => null)
  // Stays false until the browser has read the stored answer, so the banner
  // never flashes at someone who already answered.
  const loaded = useState<boolean>('analytics-consent-loaded', () => false)

  function read() {
    if (!import.meta.client) return
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      choice.value = stored === 'granted' || stored === 'denied' ? stored : null
    }
    catch {
      // Private mode or blocked storage — treat it as "not answered yet".
      choice.value = null
    }
    loaded.value = true
  }

  function set(next: ConsentChoice) {
    const wasGranted = choice.value === 'granted'
    choice.value = next
    try {
      localStorage.setItem(STORAGE_KEY, next)
    }
    catch { /* nothing to do; the answer holds for this page view */ }

    // Google's tag cannot be unloaded once it is running, so withdrawing means
    // clearing its cookies and starting the page over.
    if (wasGranted && next === 'denied' && import.meta.client) {
      clearAnalyticsCookies()
      window.location.reload()
    }
  }

  function clearAnalyticsCookies() {
    const host = window.location.hostname
    // Google Analytics writes _ga and _ga_<stream>; older tags also write _gid.
    const names = document.cookie
      .split(';')
      .map(c => c.split('=')[0]?.trim() ?? '')
      .filter(name => name.startsWith('_ga') || name === '_gid')

    for (const name of names) {
      for (const domain of [host, `.${host}`, `.${host.split('.').slice(-2).join('.')}`]) {
        document.cookie = `${name}=; path=/; domain=${domain}; expires=Thu, 01 Jan 1970 00:00:00 GMT`
      }
      document.cookie = `${name}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`
    }
  }

  const showBanner = computed(() => enabled.value && loaded.value && choice.value === null)

  return { enabled, choice, loaded, showBanner, read, set }
}
