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

    @Published private(set) var bookmarks: [ReadingPositionBookmark] = []

    func start() {
        guard task == nil else {
            return
        }
        let sequence = service.readingBookmarksSequence(quran: quran)
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

    func latest(at location: ReadingPositionBookmark.Location) -> ReadingPositionBookmark? {
        ReadingBookmarkSelection.latest(at: location, in: bookmarks)
    }

    func latest(at locations: [ReadingPositionBookmark.Location]) -> ReadingPositionBookmark? {
        ReadingBookmarkSelection.latest(at: locations, in: bookmarks)
    }

    // MARK: Private

    private let service: MobileSyncReadingBookmarkService
    private let quran: Quran
    private var task: Task<Void, Never>?
}
#endif
