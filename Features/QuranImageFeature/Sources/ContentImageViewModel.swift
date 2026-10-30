//
//  ContentImageViewModel.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import AnnotationsService
import Combine
import Crashing
import ImageService
import NoorUI
import QuranAnnotations
import QuranGeometry
import QuranKit
import ReadingService
import SwiftUI
import VLogging

@MainActor
class ContentImageViewModel: ObservableObject {
    // MARK: Lifecycle

    init(reading: Reading, page: Page, imageDataService: ImageDataService, overlayService: VerseOverlayService) {
        self.page = page
        self.reading = reading
        self.imageDataService = imageDataService
        self.overlayService = overlayService
        overlays = overlayService.overlays.restricted(to: page)

        overlayService.$overlays
            .map { $0.restricted(to: page) }
            .removeDuplicates()
            .sink { [weak self] in self?.overlays = $0 }
            .store(in: &cancellables)

        overlayService.scrollRequests
            .sink { [weak self] in
                self?.scrollToVerseIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    let page: Page
    @Published var imagePage: ImagePage?
    @Published var scrollToVerse: AyahNumber?
    @Published var scale: WordFrameScale = .zero
    @Published var imageFrame: CGRect = .zero

    @Published private var suraHeaderLocations: [SuraHeaderLocation] = []
    @Published private var ayahNumberLocations: [AyahNumberLocation] = []
    @Published private var overlays: VerseOverlays

    var imageRenderingMode: QuranThemedImage.RenderingMode {
        reading.usesInvertedQuranImageRenderingInDarkMode ? .invertInDarkMode : .tinted
    }

    var decorations: ImageDecorations {
        return ImageDecorations(
            suraHeaders: suraHeaderLocations,
            ayahNumbers: ayahNumberLocations,
            drawsAyahNumbersAndSuraHeaders: reading.drawsAyahNumbersAndSuraHeaders,
            wordFrames: imagePage?.wordFrames ?? WordFrameCollection(frames: []),
            verseHighlights: overlays.versesByHighlights().mapValues { Color($0) },
            wordHighlight: overlays.pointedWord
        )
    }

    #if QURAN_SYNC
    var ayahReadingBookmarks: [AyahNumber: [ReadingBookmarkSlot]] {
        overlays.readingBookmarkSlotsByVerse
    }

    var pageReadingBookmarks: [ReadingBookmarkSlot] {
        overlays.pageReadingBookmarkSlots(on: page)
    }
    #endif

    func loadImagePage() async {
        guard ReadingPreferences.shared.reading == reading else {
            return
        }

        do {
            let imagePage = try await imageDataService.imageForPage(page)
            try Task.checkCancellation()
            guard ReadingPreferences.shared.reading == reading else {
                return
            }
            self.imagePage = imagePage

            ayahNumberLocations = try await imageDataService.ayahNumbers(page)
            if reading.drawsAyahNumbersAndSuraHeaders {
                suraHeaderLocations = try await imageDataService.suraHeaders(page)
            }

            scrollToVerseIfNeeded()
        } catch is CancellationError {
            return
        } catch {
            guard ReadingPreferences.shared.reading == reading else {
                return
            }
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quran image details")
        }
    }

    /// Scrolls only while the view is on screen, so content being replaced can't use up the navigation target.
    func onAppear() {
        isVisible = true
        scrollToVerseIfNeeded()
    }

    func onDisappear() {
        isVisible = false
    }

    /// The reader scrolled the page themselves; forget the last scroll so it isn't applied again
    /// on appearance or size changes, and so the next request scrolls even to the same verse.
    func onReaderScroll() {
        // Every drag reports; publishing an unchanged nil would still redraw the page.
        if scrollToVerse != nil {
            scrollToVerse = nil
        }
    }

    func wordAtGlobalPoint(_ point: CGPoint) -> Word? {
        let localPoint = CGPoint(
            x: point.x - imageFrame.minX,
            y: point.y - imageFrame.minY
        )
        return imagePage?.wordFrames.wordAtLocation(localPoint, imageScale: scale)
    }

    // MARK: Private

    private let imageDataService: ImageDataService
    private let overlayService: VerseOverlayService
    private let reading: Reading
    private var cancellables: Set<AnyCancellable> = []
    private var isVisible = false

    private func scrollToVerseIfNeededSynchronously() {
        // Wait until the view is on screen and `loadImagePage()` has the page.
        guard isVisible, imagePage != nil, let ayah = overlayService.overlays.firstScrollingVerse() else {
            return
        }
        logger.info("Quran Image: scrollToVerseIfNeeded \(ayah.nonLocalizedDescription)")
        scrollToVerse = ayah
        if ayah.page == page {
            // Scroll to the navigation target once; later requests keep the reader's position.
            overlayService.consumeNavigationTarget(ayah)
        }
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the overlayService value to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
