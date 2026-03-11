# Mobile Sync Local Development

This project keeps the mobile sync integration behind the `QURAN_SYNC` compilation flag.

## Enable the feature

### From Xcode

The example app target is already wired to pass `QURAN_SYNC` into `SWIFT_ACTIVE_COMPILATION_CONDITIONS`.

Swift package targets still read `QURAN_SYNC` from the build process environment via `Package.swift`, so for a clean local Xcode run:

1. Quit Xcode.
2. Launch Xcode from Terminal with `QURAN_SYNC` in the environment:

```bash
QURAN_SYNC=1 open Example/QuranEngineApp.xcodeproj
```

3. Clean the build folder before the first run after toggling the flag.

### From the command line

```bash
QURAN_SYNC=QURAN_SYNC xcrun xcodebuild build \
  -project Example/QuranEngineApp.xcodeproj \
  -scheme QuranEngineApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS'
```

## Required runtime environment variables

The sync-enabled example app uses `mobile-sync-spm` for the OAuth redirect URI and scope defaults.

For the sync path, provide:

- `QURAN_OAUTH_CLIENT_ID`
- `QURAN_OAUTH_ISSUER_URL`

Optional:

- `QURAN_OAUTH_CLIENT_SECRET`

`QURAN_OAUTH_CLIENT_SECRET` is only needed when the configured OAuth client is registered as a confidential client. If the environment supports a public PKCE client, leave the secret unset.

The package defaults currently used by the sync path are:

- redirect URI: `com.quran.oauth://callback`
- post logout redirect URI: `com.quran.oauth://callback`
- scopes: `openid,offline_access,content,user,bookmark,sync,collection,reading_session,preference,note`

The existing native fallback auth client still reads the app-level OAuth configuration when sync is not compiled in:

- `QURAN_OAUTH_CLIENT_ID`
- `QURAN_OAUTH_ISSUER_URL`
- `QURAN_OAUTH_REDIRECT_URL`
- `QURAN_OAUTH_SCOPES`
- optional `QURAN_OAUTH_CLIENT_SECRET`

## Expected behavior

When `QURAN_SYNC` is enabled and the sync OAuth environment is configured:

- Settings shows the Quran.com login/logout action.
- Bookmarks shows the sync sign-in banner while the user is signed out.
- Page bookmarks are stored through `mobile-sync-spm` instead of Core Data.

When the flag is disabled, or the sync client id is missing:

- the app falls back to the existing Core Data page bookmarks
- the app falls back to the existing native auth client when its app-level OAuth configuration is present

## Manual verification

1. Sign in from Settings or Bookmarks.
2. Add a page bookmark.
3. Restart the app and confirm the bookmark still appears.
4. Remove the bookmark and confirm it disappears locally.
5. If another client is available on the same account, verify the bookmark syncs across devices.
