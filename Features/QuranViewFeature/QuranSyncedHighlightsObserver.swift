#if QURAN_SYNC
    //
    //  QuranSyncedHighlightsObserver.swift
    //
    //  Created by Ahmed Nabil on 2026-05-06.
    //

    import AnnotationsService
    import FeaturesSupport
    import MobileSync
    import QuranAnnotations
    import QuranKit
    import VLogging

    @MainActor
    final class QuranSyncedHighlightsObserver {
        // MARK: Lifecycle

        init(syncService: SyncService, highlightsService: QuranHighlightsService, quran: Quran) {
            self.syncService = syncService
            self.highlightsService = highlightsService
            self.quran = quran
        }

        deinit {
            task?.cancel()
        }

        // MARK: Internal

        func start() {
            guard task == nil else {
                return
            }
            let syncService = syncService
            let highlightsService = highlightsService
            let quran = quran
            task = Task {
                do {
                    for try await collections in syncService.collectionsWithBookmarksSequence() {
                        var highlights = highlightsService.highlights
                        highlights.highlightVerses = collections.highlightedAyahs(quran: quran)
                        highlightsService.highlights = highlights
                    }
                } catch {
                    logger.error("Failed to observe synced highlights: \(error)")
                }
            }
        }

        // MARK: Private

        private let syncService: SyncService
        private let highlightsService: QuranHighlightsService
        private let quran: Quran
        private var task: Task<Void, Never>?
    }
#endif
