//
//  ContentLineViewModel.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import ImageService
import NoorUI
import QuranKit
import SwiftUI
import VLogging

@MainActor
final class ContentLineViewModel: ObservableObject {
    // MARK: Lifecycle

    init(reading: Reading, page: Page, linePageAssetService: LinePageAssetService) {
        self.reading = reading
        self.page = page
        self.linePageAssetService = linePageAssetService
    }

    // MARK: Internal

    let page: Page

    @Published var assets: LinePageAssets?

    var imageRenderingMode: QuranThemedImage.RenderingMode {
        [.tajweed, .hafs_1440, .hafs_1441].contains(reading) ? .invertInDarkMode : .tinted
    }

    func loadLinePage() async {
        let page = page
        let linePageAssetService = linePageAssetService

        let result = linePageAssetService.assetsForPage(page)

        switch result {
        case .available(let assets):
            self.assets = assets
        case .unavailable:
            logger.warning("Quran Line Page: assets unavailable for page \(page.pageNumber)")
        }
    }

    func layout(for availableSize: CGSize) -> LinePageLayout? {
        guard let assets else {
            return nil
        }

        let orientation: LinePageOrientation = availableSize.height > availableSize.width ? .portrait : .landscape
        return geometryEngine.layout(
            LinePageGeometryInput(
                availableSize: availableSize,
                orientation: orientation,
                pageParity: page.pageNumber.isMultiple(of: 2) ? .even : .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: LinePageGeometryData(
                    lineCount: assets.lines.count,
                    highlightSpans: [],
                    ayahMarkers: [],
                    suraHeaders: [],
                    sidelines: []
                ),
                suraHeaderAspectRatio: suraHeaderAspectRatio
            )
        )
    }

    func lineImage(for lineNumber: Int) -> UIImage? {
        assets?.lines.first(where: { $0.lineNumber == lineNumber })?.image
    }

    // MARK: Private

    private let reading: Reading
    private let linePageAssetService: LinePageAssetService
    private let geometryEngine = LinePageGeometryEngine()

    private var suraHeaderAspectRatio: CGFloat {
        let image = NoorImage.suraHeader.uiImage
        return image.size.height / image.size.width
    }
}
