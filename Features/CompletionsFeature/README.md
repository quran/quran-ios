# CompletionsFeature

This module implements the **Reading Journey** (Completions) feature, which allows users to create and track multiple independent Quran reading journeys from start to finish.

---

## Overview

A *Completion* represents a single reading journey through the Quran. Users can:

- Create multiple named journeys (e.g. "Ramazan 2026")
- Track reading progress via bookmarks placed during Quran reading
- View statistics such as pages read, pages remaining, pace, and estimated finish date
- Mark a journey as finished or delete it at any time

---

## Architecture

The feature follows the **MVVM + Builder** pattern used throughout the app, with a `UIHostingController` wrapping SwiftUI views.

```
CompletionsBuilder
    └── CompletionsViewController  (UIHostingController)
            └── CompletionsView  (SwiftUI)
                    └── CompletionDetailView  (SwiftUI, pushed via NavigationLink)
```

### Files

| File | Role |
|---|---|
| `CompletionsBuilder.swift` | Wires dependencies and builds the module |
| `CompletionsViewController.swift` | UIKit host; owns the `+` bar button item |
| `CompletionsView.swift` | List of all completions; create / rename / delete via swipe |
| `CompletionsViewModel.swift` | Fetches completions, drives the list |
| `CompletionRowView.swift` | Single row showing name, progress bar, and status badge |
| `CompletionDetailView.swift` | Detail screen: summary, statistics, reading history, actions |
| `CompletionDetailViewModel.swift` | Drives the detail screen; subscribes to bookmarks and progress |
| `NewCompletionView.swift` | Sheet for naming and starting a new journey |

---

## Data Flow

```
CoreData (MO_Completion, MO_CompletionBookmark)
    └── CoreDataCompletionPersistence  [Data/CompletionPersistence]
            └── CompletionService  [Domain/CompletionService]
                    ├── CompletionsViewModel
                    └── CompletionDetailViewModel
```

### CompletionService responsibilities

- CRUD for `Completion` records
- Attach / detach `CompletionBookmark` records (linked by `completionId`, not a CoreData relationship)
- On `deleteCompletion`: cascades to remove all associated `CompletionBookmark`s and their corresponding `PageBookmark`s
- Exposes reactive `AnyPublisher` streams for real-time UI updates
- Provides `CompletionProgress` (pages read, remaining, percent, pace, estimated finish date)

### CloudKit sync

Both `MO_Completion` and `MO_CompletionBookmark` are stored in `NSPersistentCloudKitContainer`. All attributes are `optional = YES` as required by CloudKit. Deduplication is handled by:

- `CoreDataCompletionUniquifier` — keeps the most recently started completion per UUID
- `CoreDataCompletionBookmarkUniquifier` — keeps the most recently created bookmark per UUID

---

## Reading Session Integration

When a user taps the bookmark button in the Quran reader (`QuranViewFeature`):

1. If there are in-progress completions, an action sheet is presented listing all of them.
2. The user picks a completion (or chooses "Without completion").
3. The choice is remembered for the session (`CompletionSessionState`).
4. A `CompletionBookmark` is recorded alongside the regular `PageBookmark`.
5. Long-pressing the bookmark button resets the session choice.

This is wired through `QuranInteractor` (session state) and `QuranViewController` (UI presentation).

---

## Bookmarks Integration

The `BookmarksFeature` was extended to show which completion a bookmark belongs to:

- `BookmarksViewModel` subscribes to all completion bookmarks and completion names.
- Each bookmark row shows the completion name as a subtitle (e.g. "2 minutes ago\nRamazan 2026").
- Bookmarks that are associated with a completion but are not the highest-page bookmark for that completion are hidden from the list (only the furthest bookmark per completion is shown).

---

## Navigation

`CompletionsViewController` is embedded as a child view controller inside `BookmarksSegmentedViewController` (in `AppStructureFeature`), alongside `BookmarksViewController`. The segmented controller:

- Syncs the active child's `navigationItem` (title, left and right bar button items) to its own `navigationItem` on every segment switch.
- Resets Bookmarks edit mode when switching away from it.
- Propagates bar item changes from `BookmarksViewController` dynamically (edit ↔ done transitions).
