# Mobile Sync Local Development

This project keeps the mobile sync integration behind the `QURAN_SYNC` compilation flag.

## Enable the feature

### Build flags

Package targets read `QURAN_SYNC` from the process environment in `Package.swift`. Any non-empty value other than `0` enables package sync support. Use `1` by convention:

```bash
QURAN_SYNC=1
```

Use an empty, unset, or `0` value for the no-sync path:

```bash
QURAN_SYNC=
# or
QURAN_SYNC=0
```

The environment value only affects Swift Package evaluation. To compile app or project code guarded by `#if QURAN_SYNC`, add `QURAN_SYNC` to the target's `SWIFT_ACTIVE_COMPILATION_CONDITIONS` / "Active Compilation Conditions" build setting, or pass `-D QURAN_SYNC` through `OTHER_SWIFT_FLAGS`.

When switching modes outside the Makefile, use separate DerivedData paths or **Product > Clean Build Folder** so Xcode does not reuse build products from the other mode.

### From the command line

Use the Makefile targets for local verification:

```bash
make build-example-no-sync
make build-example-sync
```

These targets use separate DerivedData paths under `.build/DerivedData/no-sync` and `.build/DerivedData/sync`, so switching sync modes does not reuse stale build products and each mode still gets incremental builds. No package-cache reset is needed.

The sync target sets `QURAN_SYNC` for `Package.swift` and passes `-D QURAN_SYNC` only to the Example app target:

```bash
QURAN_SYNC=1 xcrun xcodebuild \
  -derivedDataPath .build/DerivedData/sync \
  build \
  -project Example/QuranEngineApp.xcodeproj \
  -scheme QuranEngineApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS' \
  'OTHER_SWIFT_FLAGS=$(inherited) -D QURAN_SYNC'
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
