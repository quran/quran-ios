import ImageService
import NoorUI
import QuranGeometry
import QuranKit
import UIKit

/// Shared production layout inputs, also used by the resource integration audit.
@MainActor
enum ContentLineLayoutBuilder {
    static func input(
        page: Page,
        availableSize: CGSize,
        data: LinePageGeometryData,
        showHeaderFooter: Bool,
        showSidelines: Bool,
        showLineDividers: Bool,
        highlightedVerses: Set<AyahNumber> = []
    ) -> LinePageGeometryInput {
        LinePageGeometryInput(
            availableSize: availableSize,
            orientation: availableSize.height > availableSize.width ? .portrait : .landscape,
            pageParity: page.pageNumber.isMultiple(of: 2) ? .even : .odd,
            displaySettings: LinePageDisplaySettings(
                showHeaderFooter: showHeaderFooter,
                showSidelines: showSidelines && !data.sidelines.isEmpty,
                showLineDividers: showLineDividers && page.pageNumber > 3
            ),
            data: data,
            highlights: LinePageHighlightState(highlightedVerses: highlightedVerses),
            suraHeaderAspectRatio: suraHeaderAspectRatio
        )
    }

    private static var suraHeaderAspectRatio: CGFloat {
        let image = NoorImage.suraHeader.uiImage
        return image.size.height / image.size.width
    }

    static func geometrySidelines(from assets: LinePageAssets) -> [LinePageGeometryData.Sideline] {
        assets.sidelines.map {
            LinePageGeometryData.Sideline(
                id: $0.imageURL.lastPathComponent,
                targetLine: $0.targetLine,
                direction: $0.direction,
                intrinsicSize: imagePixelSize($0.image)
            )
        }
    }

    private static func imagePixelSize(_ image: UIImage) -> CGSize {
        if let cgImage = image.cgImage {
            return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        }
        return CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
    }
}
