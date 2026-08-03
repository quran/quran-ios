#if QURAN_SYNC
//
//  QuranSyncedCollectionsObserver.swift
//

import AnnotationsService
import VLogging

@MainActor
final class QuranSyncedCollectionsObserver {
    // MARK: Lifecycle

    init(service: AyahBookmarkCollectionService) {
        self.service = service
    }

    deinit {
        task?.cancel()
    }

    // MARK: Internal

    private(set) var collections: [AyahBookmarkCollection] = []

    func start() {
        guard task == nil else {
            return
        }
        let service = service
        task = Task {
            do {
                for try await collections in service.collectionsSequence() {
                    self.collections = collections
                }
            } catch {
                logger.error("Failed to observe synced bookmark collections: \(error)")
            }
        }
    }

    // MARK: Private

    private let service: AyahBookmarkCollectionService
    private var task: Task<Void, Never>?
}
#endif
