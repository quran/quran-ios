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

@MainActor
class ContentImageViewModel: ObservableObject {
    // MARK: Lifecycle

    init(reading: Reading, page: Page, imageDataService: ImageDataService, highlightsService: QuranHighlightsService) {
        self.page = page
        self.reading = reading
        self.imageDataService = imageDataService
        self.highlightsService = highlightsService
        highlights = highlightsService.highlights

        highlightsService.$highlights
            .sink { [weak self] in self?.highlights = $0 }
            .store(in: &cancellables)
    }

    // MARK: Internal

    let page: Page
    @Published var imagePage: ImagePage?
    @Published var suraHeaderLocations: [SuraHeaderLocation] = []
    @Published var ayahNumberLocations: [AyahNumberLocation] = []
    @Published var highlights: QuranHighlights

    @Published var scale: WordFrameScale = .zero
    @Published var imageFrame: CGRect = .zero

    var decorations: [ImageDecoration] {
        var decorations: [ImageDecoration] = []

        for suraHeaderLocation in suraHeaderLocations {
            decorations.append(.suraHeader(suraHeaderLocation.rect))
        }

        for ayahNumberLocation in ayahNumberLocations {
            decorations.append(.ayahNumber(ayahNumberLocation.ayah.ayah, ayahNumberLocation.center))
        }

        // remove duplicate highlights
        let versesByHighlights = highlights.versesByHighlights()
        for (ayah, color) in versesByHighlights {
            for frame in imagePage?.wordFrames.wordFramesForVerse(ayah) ?? [] {
                decorations.append(.color(Color(color), frame.rect))
            }
        }

        if let word = highlights.pointedWord, let frame = imagePage?.wordFrames.wordFrameForWord(word) {
            decorations.append(.color(QuranHighlights.wordHighlightColor, frame.rect))
        }
        return decorations
    }

    func loadImagePage() async {
        do {
            imagePage = try await imageDataService.imageForPage(page)
            if reading == .hafs_1421 {
                suraHeaderLocations = try await imageDataService.suraHeaders(page)
                ayahNumberLocations = try await imageDataService.ayahNumbers(page)
            }
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quran image details")
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
    private let highlightsService: QuranHighlightsService
    private let reading: Reading

    private var cancellables: Set<AnyCancellable> = []
}
