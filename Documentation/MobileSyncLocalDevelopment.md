# Mobile Sync Local Development

This project keeps the mobile sync integration behind the `QURAN_SYNC` compilation flag.

## Enable the feature

### From Xcode

1. Open `Example/QuranEngineApp.xcodeproj` or `Example/QuranEngineApp.xcworkspace`.
2. Select the `QuranEngineApp` target.
3. Open `Build Settings`.
4. Add a user-defined build setting named `QURAN_SYNC` with the value `QURAN_SYNC` for the configuration you want to run.
5. Clean the build folder before the first run after toggling the flag.

### From the command line

```bash
QURAN_SYNC=QURAN_SYNC xcrun xcodebuild build \
  -project Example/QuranEngineApp.xcodeproj \
  -scheme QuranEngineApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS'
```

## Required runtime environment variables

The example app reads the OAuth configuration from environment variables. All of the following values are required:

- `QURAN_OAUTH_CLIENT_ID`
- `QURAN_OAUTH_ISSUER_URL`
- `QURAN_OAUTH_REDIRECT_URL`
- `QURAN_OAUTH_SCOPES`

`QURAN_OAUTH_CLIENT_SECRET` is intentionally not used in the example app.

`QURAN_OAUTH_SCOPES` should be provided as a comma-separated list, for example:

```text
openid,offline_access,content,user,bookmark,sync,collection,reading_session,preference,note
```

## Expected behavior

When `QURAN_SYNC` is enabled and the OAuth environment is configured:

- Settings shows the Quran.com login/logout action.
- Bookmarks shows the sync sign-in banner while the user is signed out.
- Page bookmarks are stored through `mobile-sync-spm` instead of Core Data.

When the flag is disabled, or the OAuth environment is missing:

- the app falls back to the existing Core Data page bookmarks
- the app falls back to the existing native auth client when sync is not compiled in

## Manual verification

1. Sign in from Settings or Bookmarks.
2. Add a page bookmark.
3. Restart the app and confirm the bookmark still appears.
4. Remove the bookmark and confirm it disappears locally.
5. If another client is available on the same account, verify the bookmark syncs across devices.
