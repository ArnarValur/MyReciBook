# Storage creds runbook — Drive + Dropbox, console → dev.env → live
*Written 2026-08-06. End state: two real values in the env files, storage
connect works on the S21. Total ~35 min. Everything else is already built
(storage 3h, full on placeholder creds).*

## Plain words first: what you're actually doing
OAuth is the "connect your account" handshake. Instead of the app ever seeing
your Dropbox/Google password, the app sends you to the real Dropbox/Google
login page in your browser; you say yes; the browser bounces back to the app
(via the `com.merkurialstudio.myrecibook://oauth2` return address already
registered in the manifest) carrying a one-time code; the app trades that code
for tokens it stores locally. PKCE is the anti-theft add-on: the app proves it
started the handshake, so no app secret ever needs to live in the APK — which
is why you'll only copy **public identifiers** today, never secrets.

The two IDs you're fetching are just "this is which app is asking":
- **Dropbox App key** — identifies MyReciBook to Dropbox
- **Drive Client ID** — identifies MyReciBook to Google

Why these two setups fit the bet: Dropbox **App folder** and Drive
**drive.file** are the minimal-trust modes — the app can only touch its own
folder / its own files, never the user's whole cloud. That's the user-owned-
files story (context.md, report §6.5) enforced by the platforms themselves.

```
[app] ──opens browser──► [Dropbox/Google login] ──you tap Allow──┐
[app] ◄─com.merkurialstudio.myrecibook://oauth2 + one-time code──┘
[app] ──code + PKCE proof──► tokens (stored on-device, token_store)
```

## Part A — Dropbox (~10 min)
1. https://www.dropbox.com/developers/apps → **Create app**.
2. Choose **Scoped access** → **App folder** → name it **MyReciBook**.
   The name is user-visible: their files land in `Dropbox/Apps/MyReciBook`.
3. **Permissions** tab → tick `files.metadata.read`, `files.content.read`,
   `files.content.write` → **Submit**.
4. **Settings** tab → *OAuth 2 → Redirect URIs* → add exactly:
   `com.merkurialstudio.myrecibook://oauth2` → **Add**.
5. Copy the **App key** (top of Settings). Ignore the App secret — the PKCE
   flow never uses it.

Note: new Dropbox apps run in *development* status — up to 50 connected
users. Plenty for the 12-tester alpha; **production approval before 11 Dec**
is a launch-window errand (now parked in pulse).

## Part B — Google Drive (~15 min)
1. https://console.cloud.google.com → project picker → the existing
   Gemini/Firebase project (we agreed it's the console home for keys/clients).
2. **APIs & Services → Library** → search *Google Drive API* → **Enable**.
3. **APIs & Services → OAuth consent screen** (skip what's already done from
   the Gemini key setup): External · app name *MyReciBook* · your email both
   places. Scopes: add `.../auth/drive.file` (listed as non-sensitive).
   Then **Publish app** (production). drive.file needs no Google review, and
   staying in Testing kills refresh tokens every 7 days — testers would have
   to reconnect weekly.
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**
   → type **Android**:
   - Package name: `com.merkurialstudio.myrecibook`
   - SHA-1: from the repo root, either
     `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | grep 'SHA1'`
     or `cd app/android && ./gradlew signingReport` (debug variant).
     (Code also pasted this SHA-1 in the night session's chat.)
5. **Create** → copy the **Client ID** (`…apps.googleusercontent.com`).
   Android clients have no secret and no redirect-URI field — the package
   name + SHA-1 pair IS the registration; the app's package-name scheme
   return address is the standard AppAuth pattern.

## Part C — wire it and prove it (~10 min)
1. Repo root `.env` — append two lines (shell form, this file is sourced by
   the spike harness):
   ```
   export DRIVE_CLIENT_ID=…apps.googleusercontent.com
   export DROPBOX_APP_KEY=xxxxxxxxxxxxxxx
   ```
2. Regenerate the device mirror (technical rule 6 — `--dart-define-from-file`
   can't read `export` lines):
   `sed -E 's/^export //' .env > app/dev.env`
3. Run on the S21 from `app/`:
   `flutter run --dart-define-from-file=dev.env`
4. Verify, in order:
   - Storage screen: the "awaiting keys in this build" captions are gone.
   - Connect Dropbox → browser opens → Allow → connected card shows.
   - Connect Drive → same.
   - Save any recipe → `Apps/MyReciBook` on dropbox.com shows the JSON; on
     drive.google.com the app's files are visible to YOU in full (drive.file
     limits the app's view, not yours).
   - Kill and reopen the app → still connected (token store held).

## If it fights back
- Google "redirect_uri_mismatch / invalid_request": tell Code — fallback is
  the reversed-client-ID scheme, a small manifest+oauth.dart swap (~15 min).
- Dropbox "invalid redirect": the URI in step A4 isn't byte-identical.
- Google "access blocked / unverified": consent screen wasn't published, or
  the client's SHA-1 isn't the keystore that signed the build on the phone.
- Browser returns but the app doesn't finish: reproduce with
  `flutter run` attached and hand Code the log.

## Hygiene + later
- Both `.env` and `app/dev.env` are gitignored — keep it that way; the two
  IDs are public identifiers, but env files also carry the Gemini key.
- Before Play upload (launch window): add the **Play App Signing** SHA-1 to
  the same Android client, or Drive connect breaks in store builds — parked
  in pulse with the Dropbox production approval.
- Token store is plain JSON on device — hardening stays parked pre-production.

## References
- https://developers.google.com/identity/protocols/oauth2/native-app
- https://github.com/openid/AppAuth-Android (redirect-scheme pattern)
- https://developers.dropbox.com/oauth-guide
