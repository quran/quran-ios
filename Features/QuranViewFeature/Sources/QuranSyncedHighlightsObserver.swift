#if QURAN_SYNC
//
//  QuranSyncedHighlightsObserver.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

import AnnotationsService
import QuranAnnotations
import VLogging

@MainActor
final class QuranSyncedHighlightsObserver {
    // MARK: Lifecycle

    init(ayahHighlightService: MobileSyncAyahHighlightService, highlightsService: QuranHighlightsService) {
        self.ayahHighlightService = ayahHighlightService
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
        let ayahHighlightService = ayahHighlightService
        let highlightsService = highlightsService
        task = Task {
            await observeHighlights(
                using: ayahHighlightService,
                highlightsService: highlightsService
            )
        }
    }

    private func observeHighlights(
        using service: MobileSyncAyahHighlightService,
        highlightsService: QuranHighlightsService
    ) async {
        do {
            for try await highlightedAyahs in service.highlightsSequence() {
                var highlights = highlightsService.highlights
                highlights.highlightVerses = highlightedAyahs
                highlightsService.highlights = highlights
            }
        } catch {
            logger.error("Failed to observe synced highlights: \(error)")
        }
    }

    // MARK: Private

    private let ayahHighlightService: MobileSyncAyahHighlightService
    private let highlightsService: QuranHighlightsService
    private var task: Task<Void, Never>?
}
#endif
