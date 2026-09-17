# Canonical URLs — fix report

*2026-09-17, branch `fix/canonical-urls`, folded to `main`, not pushed. For the
Search Console reason "Duplicate, Google chose different canonical than user"
(16 Sept 2026). You said "feel free to deploy", so this is LIVE on
myrecibook.com already; the deploy step below is done.*

## The short version

Every page had many addresses that all answered 200 with their own canonical
tag. Google picked one address per page for itself, the site said another,
and Search Console filed the rest as duplicates.

Now each page has ONE address: `https://myrecibook.com/path` (no www, no
trailing slash, no `index.html`, English only). Every other spelling answers
a single 301 straight to that address. The sitemap lists only those four
addresses.

## How the site is built and served

- Nuxt 4 static site (`pnpm generate`) in `website/`, modules `@nuxtjs/seo`
  (sitemap, robots, canonical tags) and `@nuxtjs/i18n` (seven locale files).
- Served by nginx 1.27 in a container on Cloud Run (project `myrecibook-prod`,
  service `myrecibook-website`, europe-west1). Both `myrecibook.com` and
  `www.myrecibook.com` are Cloud Run domain mappings onto that one service.
  No Cloudflare, no load balancer.
- Where the rules live: `website/nuxt.config.ts` (canonical tag, sitemap,
  robots, locales), `website/nginx.conf` (which URL serves what, redirects),
  no other place.

## What was wrong (checked live on 16/17 Sept)

| Variant | Before | Duplicate? |
|---|---|---|
| `http://` | 302 → https (Cloud Run's front door) | no, expected |
| `www.myrecibook.com/…` | 200, same page, canonical says non-www | **yes** |
| `/privacy/` (trailing slash) | 200, same page | **yes** |
| `/privacy/index.html`, `/index.html` | 200, same page | **yes** |
| `/Privacy` (uppercase) | 404 | no |
| `?utm_source=…` | 200, canonical without query | no (proper canonical) |
| `/is /sv /nb /da /fi /fo` + subpages | 200, own canonical (`…/da/privacy`) | **yes — the main cause** |
| `/200.html`, `/404.html` | 200, marked "index, follow" | shells, not pages |
| `/sitemap.xml` | 200 HTML meta-refresh → `/sitemap_index.xml` | a needless hop |

The main cause: the six language copies. Translation is paused (market
Decision 2, 2026-09-01) and the language picker is hidden, but the pages were
still built, still reachable, and listed in the sitemap with hreflang.
Danish, Finnish and Faroese are 4 of 175 strings translated, Icelandic and
Swedish half, Norwegian mostly. So `/da/privacy` was the English privacy page
under another address with a canonical tag claiming to be its own page.
Google refused that claim and chose `/privacy` — exactly the reported reason.
Nothing on the site linked to those pages; Google found them through the
sitemap only.

## Canonical form chosen

`https://myrecibook.com/<path>` — no trailing slash. This is what every
canonical tag, every internal link and the sitemap already used.

## What changed, file by file

**`website/nuxt.config.ts`**
- The seven locales moved into an `allLocales` list; a new `liveLocales = ['en']`
  filters what gets built. Only English is published. The locale files, the
  layout wiring and the hidden picker are untouched. To publish a language
  later: add its code to `liveLocales` and remove it from the nginx locale
  redirect.
- `site.trailingSlash: false` written out (it was the default; now it is a
  stated choice).
- `sitemap: { sitemaps: false }` — one flat `/sitemap.xml` instead of a
  sitemap index split per language. `robots.txt` now points at `/sitemap.xml`.

**`website/nginx.conf`** (redirect rules; every one lands in one hop)
- `www.myrecibook.com/…` → `https://myrecibook.com/…` (301).
- `/is`, `/is/`, `/is/privacy`, `/is/privacy/index.html` and the same for
  sv, nb, da, fi, fo → the English page (301).
- `/path/` and `/path/index.html` → `/path`; `/index.html` → `/` (301).
  Query strings survive the redirect (`/privacy/?ref=y` → `/privacy?ref=y`).
- `/sitemap_index.xml` and `/__sitemap__/xx.xml` → `/sitemap.xml` (301), so
  the address Search Console knows keeps working.
- `/200.html` and `/404.html` get an `X-Robots-Tag: noindex, nofollow` header.
- A staging host (run.app) redirects onto itself and stays noindex, as before.
- The `$origin` map decides where a redirect lands: the real domain and www
  both go to `https://myrecibook.com`; any other host goes to itself.

Nothing else was touched: no page content, no design, no app code.

## Proof — local build in the real container

Built with `pnpm generate`, then the Dockerfile as deployed, then curl with
the `Host` header set to each domain. Columns: URL, status → Location,
canonical tag (200 only), X-Robots-Tag header when present.

```
##### Host: myrecibook.com
myrecibook.com/                  200 -> -                                      canonical=https://myrecibook.com/
myrecibook.com/index.html        301 -> https://myrecibook.com/
myrecibook.com/privacy           200 -> -                                      canonical=https://myrecibook.com/privacy
myrecibook.com/privacy/          301 -> https://myrecibook.com/privacy
myrecibook.com/privacy/index.html 301 -> https://myrecibook.com/privacy
myrecibook.com/terms             200 -> -                                      canonical=https://myrecibook.com/terms
myrecibook.com/terms/            301 -> https://myrecibook.com/terms
myrecibook.com/contact           200 -> -                                      canonical=https://myrecibook.com/contact
myrecibook.com/contact/          301 -> https://myrecibook.com/contact
myrecibook.com/privacy?utm_source=x 200 -> -                                      canonical=https://myrecibook.com/privacy
myrecibook.com/privacy/?ref=y    301 -> https://myrecibook.com/privacy?ref=y
myrecibook.com/Privacy           404 -> -
myrecibook.com/is                301 -> https://myrecibook.com/
myrecibook.com/is/               301 -> https://myrecibook.com/
myrecibook.com/is/privacy        301 -> https://myrecibook.com/privacy
myrecibook.com/is/privacy/       301 -> https://myrecibook.com/privacy
myrecibook.com/is/privacy/index.html 301 -> https://myrecibook.com/privacy
myrecibook.com/nb/terms          301 -> https://myrecibook.com/terms
myrecibook.com/da                301 -> https://myrecibook.com/
myrecibook.com/fo/contact        301 -> https://myrecibook.com/contact
myrecibook.com/sv/index.html     301 -> https://myrecibook.com/
myrecibook.com/island            404 -> -
myrecibook.com/sitemap.xml       200 -> -
myrecibook.com/sitemap.xml/      301 -> https://myrecibook.com/sitemap.xml
myrecibook.com/sitemap_index.xml 301 -> https://myrecibook.com/sitemap.xml
myrecibook.com/__sitemap__/en.xml 301 -> https://myrecibook.com/sitemap.xml
myrecibook.com/robots.txt        200 -> -
myrecibook.com/200.html          200 -> -                                        X-Robots-Tag: noindex, nofollow
myrecibook.com/404.html          200 -> -                                        X-Robots-Tag: noindex, nofollow
myrecibook.com/nope              404 -> -
myrecibook.com/screenshots/      301 -> https://myrecibook.com/screenshots

##### Host: www.myrecibook.com
www.myrecibook.com/              301 -> https://myrecibook.com/
www.myrecibook.com/index.html    301 -> https://myrecibook.com/
www.myrecibook.com/privacy       301 -> https://myrecibook.com/privacy
www.myrecibook.com/privacy/      301 -> https://myrecibook.com/privacy
www.myrecibook.com/privacy/index.html 301 -> https://myrecibook.com/privacy
www.myrecibook.com/terms         301 -> https://myrecibook.com/terms
www.myrecibook.com/is            301 -> https://myrecibook.com/
www.myrecibook.com/is/           301 -> https://myrecibook.com/
www.myrecibook.com/is/privacy    301 -> https://myrecibook.com/privacy
www.myrecibook.com/is/privacy/   301 -> https://myrecibook.com/privacy

##### Host: staging (run.app)
…/                200 canonical=https://myrecibook.com/          X-Robots-Tag: noindex, nofollow
…/privacy/        301 -> https://<staging host>/privacy          X-Robots-Tag: noindex, nofollow
…/is              301 -> https://<staging host>/                 X-Robots-Tag: noindex, nofollow
```

The built sitemap (`.output/public/sitemap.xml`) lists exactly
`https://myrecibook.com/`, `/contact`, `/privacy`, `/terms`, each with
hreflang `en` and `x-default` pointing at itself. Internal links in the built
pages are `/`, `/contact`, `/privacy`, `/terms` — the canonical form.

## Proof — live

Deployed 2026-09-17 late evening: staging first (dev project, revision
`myrecibook-website-staging-00012`), then production via `website/deploy-prod.sh`.
Curl against the real domains, same columns as above:

```
##### https://myrecibook.com
myrecibook.com/                      200 -> -                                   canonical=https://myrecibook.com/ 
myrecibook.com/index.html            301 -> https://myrecibook.com/              
myrecibook.com/privacy               200 -> -                                   canonical=https://myrecibook.com/privacy 
myrecibook.com/privacy/              301 -> https://myrecibook.com/privacy       
myrecibook.com/privacy/index.html    301 -> https://myrecibook.com/privacy       
myrecibook.com/terms                 200 -> -                                   canonical=https://myrecibook.com/terms 
myrecibook.com/terms/                301 -> https://myrecibook.com/terms         
myrecibook.com/contact               200 -> -                                   canonical=https://myrecibook.com/contact 
myrecibook.com/contact/              301 -> https://myrecibook.com/contact       
myrecibook.com/privacy/?ref=y        301 -> https://myrecibook.com/privacy?ref=y  
myrecibook.com/is                    301 -> https://myrecibook.com/              
myrecibook.com/is/                   301 -> https://myrecibook.com/              
myrecibook.com/is/privacy            301 -> https://myrecibook.com/privacy       
myrecibook.com/da/privacy/index.html 301 -> https://myrecibook.com/privacy       
myrecibook.com/nb/terms              301 -> https://myrecibook.com/terms         
myrecibook.com/fo                    301 -> https://myrecibook.com/              
myrecibook.com/sitemap.xml           200 -> -                                    
myrecibook.com/sitemap_index.xml     301 -> https://myrecibook.com/sitemap.xml   
myrecibook.com/__sitemap__/en.xml    301 -> https://myrecibook.com/sitemap.xml   
myrecibook.com/robots.txt            200 -> -                                    
myrecibook.com/200.html              200 -> -                                    x-robots-tag: noindex, nofollow

##### https://www.myrecibook.com
www.myrecibook.com/                  301 -> https://myrecibook.com/              
www.myrecibook.com/index.html        301 -> https://myrecibook.com/              
www.myrecibook.com/privacy           301 -> https://myrecibook.com/privacy       
www.myrecibook.com/privacy/          301 -> https://myrecibook.com/privacy       
www.myrecibook.com/privacy/index.html 301 -> https://myrecibook.com/privacy       
www.myrecibook.com/terms             301 -> https://myrecibook.com/terms         
www.myrecibook.com/terms/            301 -> https://myrecibook.com/terms         
www.myrecibook.com/contact           301 -> https://myrecibook.com/contact       
www.myrecibook.com/contact/          301 -> https://myrecibook.com/contact       
www.myrecibook.com/privacy/?ref=y    301 -> https://myrecibook.com/privacy?ref=y  
www.myrecibook.com/is                301 -> https://myrecibook.com/              
www.myrecibook.com/is/               301 -> https://myrecibook.com/              
www.myrecibook.com/is/privacy        301 -> https://myrecibook.com/privacy       
www.myrecibook.com/da/privacy/index.html 301 -> https://myrecibook.com/privacy       
www.myrecibook.com/nb/terms          301 -> https://myrecibook.com/terms         
www.myrecibook.com/fo                301 -> https://myrecibook.com/              
www.myrecibook.com/sitemap.xml       301 -> https://myrecibook.com/sitemap.xml   
www.myrecibook.com/sitemap_index.xml 301 -> https://myrecibook.com/sitemap.xml   
www.myrecibook.com/__sitemap__/en.xml 301 -> https://myrecibook.com/sitemap.xml   
www.myrecibook.com/robots.txt        301 -> https://myrecibook.com/robots.txt    
www.myrecibook.com/200.html          200 -> -                                    x-robots-tag: noindex, nofollow

##### http
http://myrecibook.com/privacy/       302 -> https://myrecibook.com/privacy/
http://www.myrecibook.com/is         302 -> https://www.myrecibook.com/is
##### live sitemap
<loc>https://myrecibook.com/</loc>
<loc>https://myrecibook.com/contact</loc>
<loc>https://myrecibook.com/privacy</loc>
<loc>https://myrecibook.com/terms</loc>
Sitemap: https://myrecibook.com/sitemap.xml
```

Two things to read carefully in that output:

- `http://…` answers a **302** from Google's Cloud Run front door to the same
  host over https, and only then our 301 fires. So `http://myrecibook.com/privacy/`
  is two hops. That first hop is not ours to change; Google follows both.
- `www.myrecibook.com/200.html` still answers 200 (the noindex rule for the
  shell files runs before the www rule). It is noindexed and nothing links to
  it, so it was left alone.


## What you must do by hand

Deploy is done (staging and production, verified above). What is left:

1. Search Console → Pages → "Duplicate, Google chose different canonical than
   user" → **Validate fix**.
2. Search Console → URL inspection → **Request indexing** for
   `https://myrecibook.com/`, `/privacy`, `/terms`, `/contact`.
3. Search Console → Sitemaps: add `https://myrecibook.com/sitemap.xml`. The
   old `sitemap_index.xml` entry can stay (it 301s) or be removed.
4. Google Play console: the privacy policy URL is entered as
   `https://www.myrecibook.com/privacy`. It now 301s to the non-www page,
   which Play accepts, but changing it to `https://myrecibook.com/privacy`
   there is cleaner.
5. Google Analytics: the web stream is labelled `https://www.myrecibook.com`.
   That is a label only; hits still arrive. Rename when convenient.

## Not sure about / left alone on purpose

- **"Page with redirect"**: expected and correct for every variant above.
  `http://` is a 302 from Google's Cloud Run front door, not from nginx, and
  cannot be changed from this repo. Harmless.
- **"Alternate page with proper canonical tag"**: `?utm_…` and other query
  addresses keep serving the page (analytics needs the parameters) with the
  canonical tag pointing at the clean address. Ignore, as you said.
- **Uppercase paths** (`/Privacy`) are 404 and always were; nginx cannot
  lowercase without an extra module. Not a duplicate, left as is.
- **The six language copies are gone from the live site** for now, redirected
  to English. That follows the site's own rule (i18n D9: no language shows
  until it is finished) and Decision 2 (i18n paused). If you would rather keep
  them reachable, the alternative is a canonical tag pointing at the English
  page — but Google would still not index them, and D9 says they should not
  be live. When a language is finished: add the code to `liveLocales`, delete
  it from the nginx locale redirect, and call `useLocaleHead` in the layout
  so hreflang tags appear in the HTML (today they are only in the sitemap).
- The **staging** service on the dev project shows the same behaviour, but its
  canonical tags point at the production domain as before — by design, it is
  noindex.
