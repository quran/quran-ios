//
//  ForegroundSync.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

#if QURAN_SYNC
import Combine
import MobileSync
import UIKit
import VLogging

/// Syncs each time the user returns to the app, so changes from other devices show without waiting for the
/// periodic sync.
///
/// MobileSync already syncs once at launch, so only a return from the background syncs, never the foreground
/// that a launch itself enters.
@MainActor
final class ForegroundSync {
    // MARK: Lifecycle

    init(quranDataService: MobileSyncDataService, notificationCenter: NotificationCenter = .default) {
        self.quranDataService = quranDataService
        self.notificationCenter = notificationCenter
    }

    // MARK: Internal

    func start() {
        notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.didEnterBackground() }
            .store(in: &cancellables)
        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.willEnterForeground() }
            .store(in: &cancellables)
    }

    func didEnterBackground() {
        isInBackground = true
    }

    /// Syncs if the app is returning from the background, and returns whether it did.
    @discardableResult
    func willEnterForeground() -> Bool {
        guard isInBackground else { return false }
        isInBackground = false
        logger.info("Quran Sync: syncing after returning to the foreground")
        // MobileSync syncs only while a user is signed in, a few seconds later so a quick switch away and back
        // syncs once, and records the run as a return to the foreground.
        quranDataService.syncOnForeground()
        return true
    }

    // MARK: Private

    private let quranDataService: MobileSyncDataService
    private let notificationCenter: NotificationCenter
    private var cancellables: Set<AnyCancellable> = []
    private var isInBackground = false
}
#endif
