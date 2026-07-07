# Mobile Sync Local Development

This project keeps the mobile sync integration behind the `QURAN_SYNC` compilation flag.

## Enable the feature

### From Xcode

Set `QURAN_SYNC` directly in the example app target build settings:

```text
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) QURAN_SYNC
```

Swift package targets also read `QURAN_SYNC` from `Package.swift`, so launch Xcode with the environment variable set when you want the package feature modules to compile with sync enabled:

```bash
launchctl setenv QURAN_SYNC 1

osascript -e 'quit app "Xcode"'
pkill -x SWBBuildService 2>/dev/null || true
pkill -x XCBBuildService 2>/dev/null || true

open -a /Applications/Xcode.app Example/QuranEngineApp.xcodeproj
```

`launchctl setenv` makes `QURAN_SYNC` visible to Xcode and its build services. A shell-scoped environment variable, for example `QURAN_SYNC=1 open ...`, may not propagate to Swift package manifest evaluation.

After toggling the flag:

1. Use **File > Packages > Reset Package Caches**.
2. Use **Product > Clean Build Folder**.
3. Build or run the example app.

To disable sync for later Xcode sessions:

```bash
launchctl unsetenv QURAN_SYNC
```

### From the command line

```bash
QURAN_SYNC=1 xcrun xcodebuild build \
  -project Example/QuranEngineApp.xcodeproj \
  -scheme QuranEngineApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS'
```

## Required runtime environment variables

For the sync path, provide:

- `QURAN_OAUTH_CLIENT_ID`

Optional:

- `QURAN_OAUTH_ENVIRONMENT`
- `QURAN_OAUTH_CLIENT_SECRET`

`QURAN_OAUTH_ENVIRONMENT` selects the Mobile Sync OAuth and API environment:

- unset, `prelive`, `staging`, or any non-`production` value: prelive
- `production`: production

`QURAN_OAUTH_CLIENT_SECRET` is only needed when the configured OAuth client is registered as a confidential client. If the environment supports a public PKCE client, leave the secret unset.

The sync auth configuration currently defined in `Container` is:

- redirect URI: `com.quran.oauth://callback`
- post logout redirect URI: `com.quran.oauth://callback`
- scopes: `openid,offline_access,content,user,bookmark,sync,collection,reading_session,preference,note`

## Expected behavior

When `QURAN_SYNC` is enabled:

- Settings shows the Quran.com login/logout action.
- Bookmarks shows the sync sign-in banner while the user is signed out.
- Page bookmarks are stored through `mobile-sync-spm` instead of Core Data.

When the flag is disabled:

- the app falls back to the existing Core Data page bookmarks
- Settings and Bookmarks show Quran.com sign-in as unavailable

## Manual verification

1. Sign in from Settings or Bookmarks.
2. Add a page bookmark.
3. Restart the app and confirm the bookmark still appears.
4. Remove the bookmark and confirm it disappears locally.
5. If another client is available on the same account, verify the bookmark syncs across devices.
