# iOS track — plan

**Status: PROPOSED 2026-08-27, unratified.** Open questions for Arnar at the bottom.
Written for a Code session to execute phase by phase; browser work stays with Arnar.

## Goal

MyReciBook on iPhone via TestFlight, built and signed entirely in the cloud — no Mac
owned, ever. First tester is Arnar's friend in Iceland (iPhone, wants off MyFitnessPal
for the food logging). Android keeps shipping first; nothing here blocks it.

Pipeline agreed 2026-08-27: Apple Developer account ($99/yr, individual, browser-managed)
→ Codemagic cloud Mac builds (free 500 min/month) → signing automated with an App Store
Connect API key → TestFlight. No 12-testers-for-14-days gate on Apple's side — one
tester works from day one.

## What carries over for free

- Every pub.dev dependency supports iOS (image_picker, mobile_scanner, printing/pdf,
  wakelock_plus, path_provider, firebase_core/crashlytics/app_check, google_fonts with
  bundled fonts, gen_l10n).
- **Storage needs no port.** `RecipeStore` already has `LocalFolderStore` (plain
  dart:io). On iOS the app's Documents directory is that folder. SAF is an
  Android-only concept; `SafBridge`/`SafFolderStore` simply never run on iOS.
- No Google sign-in in the app → Apple's "must offer Sign in with Apple" rule
  (guideline 4.8) does not apply.
- The Gemini key never ships in any build; the proxy URL + App Check story is
  platform-neutral.

## The four bridges — parity decisions

| Android bridge | iOS answer |
|---|---|
| SafBridge (folder grants) | **Not ported.** Documents dir + `LocalFolderStore`. Files-app visibility via two Info.plist keys. |
| NetBridge (platform HTTP GET) | **Ported.** dart:io's HTTP parser chokes on chunked trailers on iOS too (same VM). URLSession doesn't care. Same channel, same contract. |
| AuthBridge (OAuth redirect) | **Ported.** URL-scheme handling in AppDelegate, same channel contract. |
| ShareBridge (share-sheet intake) | **Ported, phase 2.** iOS share-in requires a Share Extension + App Group — the only genuinely new construction. Phase 1 still imports via the in-app photo picker, so the tester loop starts without it. |

Channel names, method names, and payload shapes are **copied exactly** from the Kotlin
side — the Dart side must not fork per platform beyond what's listed in phase 1 step 6.

---

## Phase 0 — accounts (Arnar, browser, no Code work)

1. Enroll in the Apple Developer Program as an individual, $99/yr
   (developer.apple.com — Apple ID, D-U-N-S not needed for individuals; approval can
   take a day or two).
2. In App Store Connect: create the app record (name MyReciBook, bundle id — see open
   question 1), and generate an **API key** (Users and Access → Integrations → App
   Store Connect API, role App Manager). Download the .p8 once, note Key ID + Issuer ID.
3. Codemagic account (codemagic.io, sign in with the Git host), connect the repo, paste
   the API key into Teams → integrations → App Store Connect.
4. Firebase console: add an **iOS app** to MyReciBook-Dev (dev project only — prod
   split stays as agreed), bundle id matching step 2. Download `GoogleService-Info.plist`
   into the repo when phase 1 creates `app/ios/Runner/`.
5. When Drive/Dropbox import should work on iOS: create an **iOS OAuth client** in the
   GCP console (Drive) and add the redirect to the Dropbox app console. Can trail
   phase 1; import doors just stay dark until then.

## Phase 1 — the iOS shell (Code)

### 1. Generate the platform folder

```
cd app && flutter create --platforms=ios --org com.merkurialstudio .
```

Commit `app/ios/` as its own commit before touching anything inside it.

### 2. Runner config (Xcode project files, edited as text)

- Bundle id `com.merkurialstudio.myrecibook` (pending open question 1).
- iOS deployment target **15.0** (App Attest needs 14+, 15 keeps pods happy).
- App icons: generate the `AppIcon.appiconset` from the existing logo asset
  (`flutter_launcher_icons` or a one-off script — whichever is less ceremony).

### 3. Info.plist

```xml
NSCameraUsageDescription          — barcode scanning + photographing recipes
NSPhotoLibraryUsageDescription    — importing recipe screenshots
UIFileSharingEnabled              = true   <!-- recipes visible in the Files app -->
LSSupportsOpeningDocumentsInPlace = true
CFBundleURLTypes:
  - scheme com.merkurialstudio.myrecibook          (oauth2 redirect)
  - scheme com.googleusercontent.apps.<iOS-client> (Drive, reversed iOS client id — NOT the Android one)
```

Purpose strings are user-facing App Review material — write them as real sentences,
and they belong in the l10n sweep eventually (`InfoPlist.strings`), English-only now.

**ATS decision needed (open question 3):** shared recipe links can be plain http.
URLSession blocks http unless `NSAllowsArbitraryLoads=true`, which App Review accepts
with a justification ("user-supplied recipe URLs"). Recommend: allow it, justify it.

### 4. NetBridge.swift

Mirror of NetBridge.kt — channel `com.merkurialstudio.myrecibook/net`, one method.

```
on "get"(url, headers):
    session = URLSession with:
        no automatic redirect following (delegate returns nil to cancel redirects —
        we re-issue manually so http→https hops survive, matching Kotlin)
        timeouts: connect 15s, total 20s per request
    repeat up to 5 redirects:
        resp = GET url with headers
        if 300..399: url = resolve(Location, against: url); continue
        body = resp bytes, capped at 10 MB (abort with error "io" past the cap)
        return {"status": Int, "body": FlutterStandardTypedData(bytes)}
    error("io", "too many redirects")
any other method → notImplemented
work off the main thread; deliver results on the main thread
```

Then in Dart, `link_fetch_client.dart` line ~19: `Platform.isAndroid` →
`Platform.isAndroid || Platform.isIOS` (the whole reason the bridge exists applies on
iOS too).

### 5. AuthBridge.swift + AppDelegate routing

Channel `com.merkurialstudio.myrecibook/auth`. Same queue-first delivery: a cold
start must retain redirects until Dart drains them.

```
state: pending: [String]   // main-thread only
on "launchUrl"(url):
    require scheme == https, else error("AUTH_IO", ...)
    UIApplication.shared.open(url)
on "takePendingRedirects": return pending; pending.removeAll()

handleOpenURL(url) -> Bool:      // called from AppDelegate application(_:open:options:)
    ours   = url.scheme == "com.merkurialstudio.myrecibook" && url.host == "oauth2"
    google = url.scheme hasPrefix "com.googleusercontent.apps."
    if !ours && !google: return false
    pending.append(url.absoluteString)
    channel.invokeMethod("onAuthRedirect", url.absoluteString) { result in
        if delivery confirmed: pending.remove(that url)   // Kotlin pattern exactly
    }
    return true
```

AppDelegate keeps FlutterAppDelegate as superclass; bridges attach in
`didFinishLaunching` after `GeneratedPluginRegistrant.register`. Route order matters
and matches MainActivity.kt: **auth first, share second** — an oauth2 redirect must
never reach the share path.

### 6. Dart branches (the complete list)

- `folder_gate.dart`: on iOS skip the folder picker; resolve the store root to
  `getApplicationDocumentsDirectory()` and construct `LocalFolderStore` /
  `LocalFolderSource`. The two-folders mental model stays intact — the folder just
  has a fixed, Files-app-visible address. No re-pick flow needed (the grant can't die).
- `link_fetch_client.dart`: guard widened (step 4).
- `app_check.dart`: provider per platform — Play Integrity on Android, **App Attest**
  on iOS (`AppleProvider.appAttestWithDeviceCheckFallback`), debug provider on
  simulators/debug builds. Register App Attest in the Firebase console (Arnar,
  browser, one toggle). Degradation contract unchanged: no config → header absent.
- Everything else: no platform forks. If a fork feels needed elsewhere, stop and put
  it in the relay instead.

### 7. codemagic.yaml (repo root)

```yaml
workflows:
  ios-testflight:
    instance_type: mac_mini_m2
    environment:
      flutter: stable
      xcode: latest
      groups: [appstore]            # holds the App Store Connect key reference
    integrations:
      app_store_connect: <key name set in phase 0.3>
    triggering: manual              # 500 free min/month — spend them on purpose
    scripts:
      - flutter pub get
      - name: automatic signing
        script: |
          xcode-project use-profiles   # Codemagic fetches/creates certs+profiles via the API key
      - flutter build ipa --release --export-options-plist=$HOME/export_options.plist
    artifacts: [build/ios/ipa/*.ipa]
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
        beta_groups: [testers]
```

Notes: working dir is `app/` (set `working_directory`). Crashlytics needs dSYMs — add
Codemagic's dSYM upload step (or the Fabric upload-symbols run-script pod adds) so
crash reports symbolicate. First build will be slow (~25–35 min, pods cold);
budget ~15 builds/month on the free tier.

### 8. Phase-1 exit

Build in Codemagic → TestFlight internal group → friend's iPhone. Verify: launch,
folder auto-resolve, photo-picker import through the live extraction server, barcode
scan, diary, PDF export, crash test-door, App Check header present on proxy calls.

## Phase 2 — share sheet intake (Code, the one new build)

iOS apps receive shares only through a **Share Extension** — a separate tiny target,
its own process, no Flutter inside it. Bridge: an **App Group** container both
processes can read.

```
App Group id: group.com.merkurialstudio.myrecibook   (Runner + extension entitlements)

ShareExtension (Swift, no UI beyond auto-complete):
  on didSelectPost / viewDidAppear:
    for each attachment (cap 10, mirror MAX_IMAGES):
      if conforms to image type:
        load file representation
        if size ≤ 25 MB:                       # mirror MAX_BYTES
          copy → groupContainer/shared/share-<epoch>-<seq>.<ext>
          # extension sanitizes the extension exactly like Kotlin: alphanumerics, ≤5 chars
      else if plain text or URL (≤100k chars):  # mirror MAX_TEXT_CHARS
        first https?:// match, trailing punctuation trimmed (Kotlin regex, verbatim)
        append → groupContainer/shared/links.txt (one per line)
    completeRequest()          # hostile/malformed share must no-op, never crash

ShareBridge.swift (inside Runner, channel com.merkurialstudio.myrecibook/share):
  drain():                     # at didFinishLaunching AND applicationDidBecomeActive
    images = files in groupContainer/shared/ moved → app cache dir /shared
    links  = lines from links.txt, then truncate the file
    queue-first + push, same as Kotlin:
      pending += paths; invokeMethod("onSharedImages", paths) { confirmed → un-queue }
      pendingLinks += links; invokeMethod("onSharedLink", each) { confirmed → un-queue }
  on "takePendingShared":      return + clear pending
  on "takePendingSharedLinks": return + clear pendingLinks
```

Dart side: `share_intake.dart` already speaks this channel — zero changes if the
contract is mirrored faithfully. The extension shows up in the iOS share sheet for
Photos and Safari; that is the moment both import doors exist on iPhone.

Extension has its own bundle id (`…myrecibook.share`), its own provisioning —
Codemagic's `use-profiles` handles it once the id exists in the developer portal.

## Phase 3 — the tester loop

- Friend added by email in App Store Connect → TestFlight app on her phone → invite.
- Internal group = instant builds, no review. (External groups need a one-time beta
  review — not needed for one tester.)
- Her checklist per round: safe areas/notch and the home-indicator gap, photo
  permission prompts read sensibly, share sheet from Photos and from Safari, import
  through the live server end to end, keyboard behavior in the editor, PDF share
  sheet. Full round before releases or after touching camera/images/permissions —
  same policy as the Android side.
- TestFlight builds expire after 90 days — a quiet month is fine, a quiet quarter
  means rebuilding before she can test again.
- No Xcode debugger exists in this pipeline: Crashlytics + TestFlight feedback are
  the instruments. Truly stuck → rent MacinCloud for an afternoon.

## Parked (explicitly not in this track's first pass)

- **Payments on iOS** — must use Apple in-app purchase (15% small-business rate).
  The billing seam is unstarted anyway; when it opens, it grows two doors at once.
  The two-weeks-free-then-1200/yr offer maps fine onto an IAP subscription.
- **App Store submission itself** — needs the privacy policy + data-safety work
  already blocking Play; write once, file in both stores. Plus App Privacy labels.
- User-picked folders on iOS (document picker + security-scoped bookmarks, iCloud
  Drive) — only if testers ask where their files live and Documents doesn't satisfy.
- Universal links, PROCESS_TEXT parity (no iOS equivalent — drop silently).

## Open questions (ratification)

1. **Bundle id** — reuse `com.merkurialstudio.myrecibook` on iOS? (Recommended: yes,
   one id everywhere; it's never been used on Apple's side so it's free to claim.)
2. **Sequencing** — start phase 0/1 now alongside i18n's string sweep, or after the
   Play closed test is filed? Phase 0 is Arnar-only and slow-cooked (Apple approval),
   so starting it early costs nothing.
3. **ATS** — allow plain-http recipe pages with a justification, or accept that
   http-only sites fail on iOS? (Recommended: allow + justify.)
4. **Share extension timing** — phase 2 before the friend's first build, or let her
   start on the photo-picker door only? (Recommended: ship phase 1 to her first;
   real feedback beats completeness.)
