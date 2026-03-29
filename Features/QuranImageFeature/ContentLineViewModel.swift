//
//  ContentLineViewModel.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import AnnotationsService
import Combine
import ImageService
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import VLogging

@MainActor
final class ContentLineViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        reading: Reading,
        page: Page,
        linePageAssetService: LinePageAssetService,
        highlightsService: QuranHighlightsService
    ) {
        self.reading = reading
        self.page = page
        self.linePageAssetService = linePageAssetService
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

    @Published var assets: LinePageAssets?
    @Published private(set) var geometryData = LinePageGeometryData(
        highlightSpans: [],
        ayahMarkers: [],
        suraHeaders: [],
        sidelines: []
    )
    @Published var highlights: QuranHighlights
    @Published var scrollToVerse: AyahNumber?

    var imageRenderingMode: QuranThemedImage.RenderingMode {
        [.tajweed, .hafs_1440, .hafs_1441].contains(reading) ? .invertInDarkMode : .tinted
    }

    var highlightColorsByVerse: [AyahNumber: Color] {
        highlights.versesByHighlights().mapValues { Color($0) }
    }

    func loadLinePage() async {
        let page = page
        let linePageAssetService = linePageAssetService

        let result = linePageAssetService.assetsForPage(page)

        switch result {
        case .available(let assets):
            self.assets = assets
            geometryData = LinePageGeometryData(
                lineCount: assets.lines.count,
                highlightSpans: [],
                ayahMarkers: [],
                suraHeaders: [],
                sidelines: geometrySidelines(from: assets)
            )

            do {
                async let highlightSpans = assets.persistence.highlightSpans(page)
                async let ayahMarkers = assets.persistence.ayahMarkers(page)
                async let suraHeaders = assets.persistence.suraHeaders(page)
                let loadedHighlightSpans = try await highlightSpans
                let loadedAyahMarkers = try await ayahMarkers
                let loadedSuraHeaders = try await suraHeaders

                geometryData = LinePageGeometryData(
                    lineCount: assets.lines.count,
                    highlightSpans: loadedHighlightSpans,
                    ayahMarkers: loadedAyahMarkers,
                    suraHeaders: loadedSuraHeaders,
                    sidelines: geometrySidelines(from: assets)
                )
            } catch {
                logger.warning("Quran Line Page: failed to load overlay data for page \(page.pageNumber): \(error)")
            }

            scrollToVerseIfNeeded()
        case .unavailable:
            logger.warning("Quran Line Page: assets unavailable for page \(page.pageNumber)")
        }
    }

    func layout(for availableSize: CGSize) -> LinePageLayout? {
        guard let assets else {
            currentLayout = nil
            return nil
        }

        let orientation: LinePageOrientation = availableSize.height > availableSize.width ? .portrait : .landscape
        let layout = geometryEngine.layout(
            LinePageGeometryInput(
                availableSize: availableSize,
                orientation: orientation,
                pageParity: page.pageNumber.isMultiple(of: 2) ? .even : .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: LinePageGeometryData(
                    lineCount: assets.lines.count,
                    highlightSpans: geometryData.highlightSpans,
                    ayahMarkers: geometryData.ayahMarkers,
                    suraHeaders: geometryData.suraHeaders,
                    sidelines: geometryData.sidelines
                ),
                highlights: LinePageHighlightState(
                    highlightedVerses: Set(highlightColorsByVerse.keys),
                    scrollingVerse: scrollToVerse
                ),
                suraHeaderAspectRatio: suraHeaderAspectRatio
            )
        )
        currentLayout = layout
        return layout
    }

    func lineImage(for lineNumber: Int) -> UIImage? {
        assets?.lines.first(where: { $0.lineNumber == lineNumber })?.image
    }

    func updateContentFrame(_ frame: CGRect) {
        contentFrame = frame
    }

    func verseAtGlobalPoint(_ point: CGPoint) -> AyahNumber? {
        guard let currentLayout else {
            return nil
        }
        let localPoint = CGPoint(
            x: point.x - contentFrame.minX,
            y: point.y - contentFrame.minY
        )
        return currentLayout.verse(at: localPoint)
    }

    // MARK: Private

    private let reading: Reading
    private let linePageAssetService: LinePageAssetService
    private let geometryEngine = LinePageGeometryEngine()
    private var cancellables: Set<AnyCancellable> = []
    private var currentLayout: LinePageLayout?
    private var contentFrame: CGRect = .zero

    private var suraHeaderAspectRatio: CGFloat {
        let image = NoorImage.suraHeader.uiImage
        return image.size.height / image.size.width
    }

    private func geometrySidelines(from assets: LinePageAssets) -> [LinePageGeometryData.Sideline] {
        assets.sidelines.map {
            LinePageGeometryData.Sideline(
                targetLine: $0.targetLine,
                direction: $0.direction,
                intrinsicSize: $0.image.size
            )
        }
    }

    private func scrollToVerseIfNeededSynchronously() {
        guard let ayah = highlights.firstScrollingVerse() else {
            return
        }
        logger.info("Quran Line Page: scrollToVerseIfNeeded \(ayah)")
        scrollToVerse = ayah
    }

    private func scrollToVerseIfNeeded() {
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
