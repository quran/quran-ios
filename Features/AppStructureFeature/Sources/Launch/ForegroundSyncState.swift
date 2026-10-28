//
//  ForegroundSyncState.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

#if QURAN_SYNC
/// Decides when the app syncs on returning to the foreground.
///
/// MobileSync already syncs once at launch, so only a return from the background syncs, never the
/// foreground that a launch itself enters.
struct ForegroundSyncState {
    mutating func didEnterBackground() {
        isInBackground = true
    }

    /// Whether this return to the foreground should sync.
    mutating func willEnterForeground() -> Bool {
        defer { isInBackground = false }
        return isInBackground
    }

    // MARK: Private

    private var isInBackground = false
}
#endif
