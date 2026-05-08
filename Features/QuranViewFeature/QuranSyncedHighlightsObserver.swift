#if QURAN_SYNC
    //
    //  QuranSyncedHighlightsObserver.swift
    //
    //  Created by Ahmed Nabil on 2026-05-06.
    //

    import AnnotationsService
    import BookmarksFeature
    import QuranAnnotations
    import QuranKit
    import VLogging

    @MainActor
    final class QuranSyncedHighlightsObserver {
        // MARK: Lifecycle

        init(ayahBookmarkCollectionService: AyahBookmarkCollectionService, highlightsService: QuranHighlightsService) {
            self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
            self.highlightsService = highlightsService
        }

        deinit {
            task?.cancel()
        }

        // MARK: Internal

        func start() {
            guard task == nil else {
                return
            }
            let ayahBookmarkCollectionService = ayahBookmarkCollectionService
            let highlightsService = highlightsService
            task = Task {
                do {
                    try await ayahBookmarkCollectionService.observeCollections { collections in
                        var highlights = highlightsService.highlights
                        highlights.highlightVerses = highlightedAyahs(from: collections)
                        highlightsService.highlights = highlights
                    }
                } catch {
                    logger.error("Failed to observe synced highlights: \(error)")
                }
            }
        }

        private func highlightedAyahs(from collections: [AyahBookmarkCollection]) -> [AyahNumber: HighlightColor] {
            var highlights: [AyahNumber: HighlightColor] = [:]
            for collection in collections {
                guard let color = HighlightColor(collectionName: collection.collection.name) else {
                    continue
                }
                for bookmark in collection.bookmarks {
                    highlights[bookmark.ayah] = color
                }
            }
            return highlights
        }

        // MARK: Private

        private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
        private let highlightsService: QuranHighlightsService
        private var task: Task<Void, Never>?
    }
#endif
