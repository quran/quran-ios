#if QURAN_SYNC
//
//  QuranReadingBookmarkObserver.swift
//

import AnnotationsService
import Combine
import QuranAnnotations
import QuranKit
import VLogging

@MainActor
final class QuranReadingBookmarkObserver {
    // MARK: Lifecycle

    init(service: MobileSyncReadingBookmarkService, quran: Quran) {
        self.service = service
        self.quran = quran
    }

    deinit {
        task?.cancel()
    }

    // MARK: Internal

    @Published private(set) var bookmark: ReadingPositionBookmark?

    func start() {
        guard task == nil else {
            return
        }
        let service = service
        let quran = quran
        task = Task { [weak self] in
            do {
                for try await bookmark in service.readingBookmarkSequence(quran: quran) {
                    self?.bookmark = bookmark
                }
            } catch is CancellationError {
            } catch {
                logger.error("Failed to observe reading bookmark: \(error)")
            }
        }
    }

    @discardableResult
    func add(at location: ReadingPositionBookmark.Location) async throws -> ReadingPositionBookmark {
        let bookmark = try await service.addReadingBookmark(at: location)
        self.bookmark = bookmark
        return bookmark
    }

    func remove() async throws -> ReadingPositionBookmark? {
        guard let bookmark else {
            return nil
        }
        guard try await service.removeReadingBookmark() else {
            return nil
        }
        self.bookmark = nil
        return bookmark
    }

    // MARK: Private

    private let service: MobileSyncReadingBookmarkService
    private let quran: Quran
    private var task: Task<Void, Never>?
}
#endif
