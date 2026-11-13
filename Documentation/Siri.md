# Siri and Shortcuts

The example app exposes its reading and listening actions through App Intents on iOS 17.2 and later. The app's iOS 15 deployment target is unchanged. The app owns these intents because playback and navigation must use the same dependencies as an ordinary app session.

The SDK exposes `AudioPlaybackIntent` from iOS 17, but this Xcode build emits an iOS 17.2 minimum in the action metadata. The feature is explicitly gated at 17.2 to match that shipped metadata.

## Available actions

| Action | Behavior |
| --- | --- |
| Continue Listening | Resumes listening for one, two, five, ten, or twenty pages. A request without an amount defaults to five pages. |
| Continue Listening to Pages | Accepts any positive integer in Shortcuts. When invoked without a count, asks how many pages to hear. |
| Continue Reading | Opens the saved reading location through `quran://continue-reading`. |

The preset listening action includes these English trigger phrases:

- “Continue listening in [app name].”
- “Continue listening to [app name] next five pages.”
- “Continue listening in [app name] for five pages.”
- “Listen to the next five pages in [app name].”

For a different count, say “Choose how many pages to hear in [app name]” and answer Siri's question, or configure the **Continue Listening to Pages** action in Shortcuts. Reading uses “Continue reading in [app name].” Replace `[app name]` with the installed app's display name; the example project is named QuranEngineApp. Siri recognition also depends on the device's language and settings, so check these phrases on a device before publishing them to users.

## Integration

`QuranAppShortcuts` registers the three actions. `AppDelegate` calls `QuranAppShortcuts.updateAppShortcutParameters()` at launch inside an `if #available(iOS 17.2, *)` check. The four intent-related Swift files belong to the application target, together with these localization tables:

- `AppIntents.strings` contains action names, descriptions, parameter names, choices, and dialogs.
- `AppShortcuts.strings` contains Siri trigger phrases. Preserve `${applicationName}` and `${amount}` in translations. This first implementation supplies English phrases; additional Siri languages need localized phrases and device validation.
- `Localizable.strings` contains the errors returned by the shared launch and playback services.

The two listening intents call `Container.shared.continueListening(pageCount:) async throws` on the main actor. This prepares the data stores and migrations through `LaunchPreparation`, starts the shared download manager, and retrieves the last reading page as a fallback. It then calls `QuranPlaybackService.continueListening(quran:fallback:pageCount:)` on the same service instance used by the reader and remote controls. This service loads the listening checkpoint, plans the bounded ayah range, prepares streaming or downloaded audio, and activates the audio session. Protected data, database, download, and player errors propagate to the intent.

The checkpoint stores sura and ayah coordinates, reciter ID, and whether the Quran has finished. It is separate from the reading position and maps its verse into the currently selected mushaf. If no usable listening checkpoint exists, playback starts at the most recent reading page's first verse, or the Quran's first verse when there is no reading history. The service uses the saved reciter when available and otherwise falls back to the selected or first available reciter.

Resume is **at verse granularity**, without a saved audio timestamp. Each verse-start callback saves that verse. A new Siri request after a pause, explicit stop, interruption, or termination therefore repeats the current verse from its beginning. Natural completion of the requested range saves the next verse; explicit stop and playback failure do not advance the checkpoint. After natural completion of the Quran's final verse, another continuation request reports completion and asks the user to choose a new starting point in the app.

The remainder of the current page counts as the first requested page. For example, five pages from the middle of page 10 ends at page 14's final verse. A positive count can exceed the remaining pages; `ListeningRange` clamps to the Quran's end before adding, including for `Int.max`. It uses the selected mushaf's page count rather than assuming 604 pages. Siri continuation uses one pass through the requested range, without verse repetitions or delays, and keeps the saved playback rate.

`AudioPlaybackIntent` keeps playback in the application process and informs the system that the action changes audio playback. Both listening actions request background execution with `supportedModes` on iOS 26 and use `openAppWhenRun = false` for iOS 17.2–25. The example already enables the `audio` background mode. The intent finishes after handing playback to the audio controller; it does not remain running for the entire recitation.

The reading action requests foreground execution and then opens the registered URL. This works on iOS 17.2 without `OpenURLIntent`, which requires iOS 18. The scene's existing URL handling is responsible for cold and warm launch routing to the saved position.

## Why there are two listening actions

An `Int` is a valid App Intent parameter, but an App Shortcut's phrase parameter must have known values. `ListeningPageAmount` supplies those values as an `AppEnum`; the separate integer action handles other counts through Shortcuts or a follow-up question. Do not replace the enum phrase slot with an arbitrary integer slot or promise that every natural-language variation will resolve.

Apple's references: [AudioPlaybackIntent](https://developer.apple.com/documentation/appintents/audioplaybackintent), [runtime behavior](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents), [intent parameters](https://developer.apple.com/documentation/appintents/adding-parameters-to-an-app-intent), and [App Shortcut phrase constraints](https://developer.apple.com/videos/play/wwdc2023/10102/?time=537).

## Verification

Build both configurations using `make build-example-no-sync` and `make build-example-sync`. In Xcode, inspect **Product > App Shortcuts Preview** to verify the extracted actions and phrases. Confirm that `AppIntents.strings`, `AppShortcuts.strings`, and extracted App Intents metadata are in the built application.

On a physical device, verify:

- Preset phrases select the intended count; a phrase without an amount uses five.
- The arbitrary-count action asks for a missing count, accepts a positive count, and asks again for zero or a negative count.
- Listening resumes independently of the last reading position, including after terminating the app.
- A request starting in the middle of a page counts that partial page as the first page, stops at the planned final ayah, and saves the next verse after natural completion.
- A new continuation request after stop or termination restarts the saved verse; it does not claim to restore an exact audio timestamp.
- Completing the final verse prevents an automatic wrap or replay and prompts the user to choose a new starting point.
- Requests near the Quran's end stop there without wrapping; alternate mushaf pagination remains correct.
- Cold, background, and locked-device requests behave correctly; inaccessible protected data produces an actionable error.
- With saved downloads pending, launch through Siri while protected data is unavailable, then unlock. Confirm download startup waits for unlock, saved batches reappear, and a subsequent listening request succeeds without restarting the app. Also verify that a background download completion received while locked is handled after unlock.
- Missing downloads, offline operation, interruptions, and another app's audio produce understandable results.
- Continue Reading opens the correct location from both a cold and warm app state.

Simulator/build checks cannot establish spoken Siri recognition, locked-device audio behavior, or audio-route behavior.
