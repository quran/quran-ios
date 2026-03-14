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
import SwiftUI
import VLogging
import WordAnnotationService

@MainActor
class ContentImageViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        reading: Reading,
        page: Page,
        imageDataService: ImageDataService,
        highlightsService: QuranHighlightsService,
        wordAnnotationService: WordAnnotationService? = nil
    ) {
        self.page = page
        self.reading = reading
        self.imageDataService = imageDataService
        self.highlightsService = highlightsService
        self.wordAnnotationService = wordAnnotationService
        highlights = highlightsService.highlights

        highlightsService.$highlights
            .sink { [weak self] in self?.highlights = $0 }
            .store(in: &cancellables)

        highlightsService.scrolling
            .sink { [weak self] in
                self?.scrollToVerseIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    let page: Page
    @Published var imagePage: ImagePage?
    @Published var suraHeaderLocations: [SuraHeaderLocation] = []
    @Published var ayahNumberLocations: [AyahNumberLocation] = []
    @Published var highlights: QuranHighlights
    @Published var scrollToVerse: AyahNumber?

    @Published var scale: WordFrameScale = .zero
    @Published var imageFrame: CGRect = .zero

    var imageRenderingMode: QuranThemedImage.RenderingMode {
        [.tajweed, .hafs_1440].contains(reading) ? .invertInDarkMode : .tinted
    }

    var decorations: ImageDecorations {
        // Add verse highlights
        var frameHighlights: [WordFrame: Color] = [:]
        let versesByHighlights = highlights.versesByHighlights()
        for (ayah, color) in versesByHighlights {
            for frame in imagePage?.wordFrames.wordFramesForVerse(ayah) ?? [] {
                frameHighlights[frame] = Color(color)
            }
        }

        // Add word highlight
        if let word = highlights.pointedWord, let frame = imagePage?.wordFrames.wordFrameForWord(word) {
            frameHighlights[frame] = QuranHighlights.wordHighlightColor
        }

        // Build tajweed colour + transliteration maps from word annotations
        var tajweedColors: [WordFrame: Color] = [:]
        var transliterations: [WordFrame: String] = [:]
        for (ayah, annotations) in highlights.wordAnnotations {
            for annotation in annotations {
                let word = Word(verse: ayah, wordNumber: annotation.wordIndex)
                guard let frame = imagePage?.wordFrames.wordFrameForWord(word) else { continue }
                if let tajweedColor = annotation.tajweedColor {
                    tajweedColors[frame] = tajweedColor.swiftUIColor
                }
                if let transliteration = annotation.transliteration, !transliteration.isEmpty {
                    transliterations[frame] = transliteration
                }
            }
        }

        return ImageDecorations(
            suraHeaders: suraHeaderLocations,
            ayahNumbers: ayahNumberLocations,
            wordFrames: imagePage?.wordFrames ?? WordFrameCollection(lines: []),
            highlights: frameHighlights,
            tajweedColors: tajweedColors,
            transliterations: transliterations
        )
    }

    func loadImagePage() async {
        do {
            imagePage = try await imageDataService.imageForPage(page)

            if reading == .hafs_1421 {
                suraHeaderLocations = try await imageDataService.suraHeaders(page)
                ayahNumberLocations = try await imageDataService.ayahNumbers(page)
            }

            scrollToVerseIfNeeded()
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quran image details")
        }

        // Load word annotations (tajweed colours + transliteration) in background.
        await loadWordAnnotations()
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
    private let highlightsService: QuranHighlightsService
    private let wordAnnotationService: WordAnnotationService?
    private let reading: Reading
    private var cancellables: Set<AnyCancellable> = []

    private func loadWordAnnotations() async {
        guard let wordAnnotationService else { return }
        do {
            let annotations = try await wordAnnotationService.annotations(for: page)
            highlights.wordAnnotations = annotations
        } catch {
            logger.error("WordAnnotations: failed to load for page \(page.pageNumber): \(error)")
        }
    }

    private func scrollToVerseIfNeededSynchronously() {
        guard let ayah = highlightsService.highlights.firstScrollingVerse() else {
            return
        }
        logger.info("Quran Image: scrollToVerseIfNeeded \(ayah)")
        scrollToVerse = ayah
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the highlightsService value to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
