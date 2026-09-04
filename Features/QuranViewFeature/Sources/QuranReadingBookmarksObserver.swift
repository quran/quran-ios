#if QURAN_SYNC
//
//  QuranReadingBookmarksObserver.swift
//

import AnnotationsService
import Combine
import Crashing
import QuranAnnotations
import QuranKit

@MainActor
final class QuranReadingBookmarksObserver {
    // MARK: Lifecycle

    init(service: MobileSyncReadingBookmarkService, quran: Quran) {
        self.service = service
        self.quran = quran
    }

    deinit {
        task?.cancel()
    }

    // MARK: Internal

    @Published private(set) var bookmarks: [PlacedReadingBookmark] = []

    func start() {
        guard task == nil else {
            return
        }
        let sequence = service.placedReadingBookmarksSequence(quran: quran)
        task = Task { [weak self] in
            do {
                for try await bookmarks in sequence {
                    self?.bookmarks = bookmarks
                }
            } catch is CancellationError {
            } catch {
                crasher.recordError(error, reason: "Failed to observe reading bookmarks in Quran")
            }
        }
    }

    func latest(at placement: PlacedReadingBookmark.Placement) -> PlacedReadingBookmark? {
        ReadingBookmarkSelection.latest(at: placement, in: bookmarks)
    }

    func latest(at placements: [PlacedReadingBookmark.Placement]) -> PlacedReadingBookmark? {
        ReadingBookmarkSelection.latest(at: placements, in: bookmarks)
    }

    // MARK: Private

    private let service: MobileSyncReadingBookmarkService
    private let quran: Quran
    private var task: Task<Void, Never>?
}
#endif
