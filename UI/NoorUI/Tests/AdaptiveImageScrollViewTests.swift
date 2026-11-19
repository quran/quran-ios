//
//  AdaptiveImageScrollViewTests.swift
//

import QuranGeometry
import SwiftUI
import UIx
import XCTest
@testable import NoorUI

@MainActor
final class AdaptiveImageScrollViewTests: XCTestCase {
    /// Mid-swipe a page sits at a fractional x, where its global frame measured 413.99999999999994 wide instead
    /// of 414. The scale and header insets must follow the image's own size, not its position on screen.
    func test_pageAtFractionalX_keepsTheScaleAndTextInsets() {
        for width in [414, 600] as [CGFloat] {
            let reference = layout(width: width, x: 0)
            assertMeasured(reference, width: width)

            for x in [108.33333333333333, 107.66666666666667] as [CGFloat] {
                XCTAssertEqual(layout(width: width, x: x), reference, "width \(width), x \(x)")
            }
        }
    }

    // MARK: Private

    private struct Layout: Equatable {
        var scale: CGFloat = 0
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var insets = EdgeInsets()
    }

    private let imageSize = CGSize(width: 1024, height: 1656)
    private let textColumn: ClosedRange<CGFloat> = 61 ... 963
    private let pageHeight: CGFloat = 896
    /// The probe header and the footer are 20 points each.
    private let headerAndFooterHeight: CGFloat = 40

    /// The image fits the content (the page width) and the space between header and footer, centred
    /// horizontally; the insets reach the text column from the content's edges.
    private func assertMeasured(_ layout: Layout, width: CGFloat, line: UInt = #line) {
        let scale = min(width / imageSize.width, (pageHeight - headerAndFooterHeight) / imageSize.height)
        let imageMargin = (width - imageSize.width * scale) / 2
        let accuracy = 1e-6
        XCTAssertEqual(layout.scale, scale, accuracy: accuracy, "\(width)", line: line)
        XCTAssertEqual(layout.xOffset, 0, accuracy: accuracy, "\(width)", line: line)
        XCTAssertEqual(layout.yOffset, 0, accuracy: accuracy, "\(width)", line: line)
        XCTAssertEqual(layout.insets.leading, imageMargin + textColumn.lowerBound * scale, accuracy: accuracy, "\(width)", line: line)
        XCTAssertEqual(
            layout.insets.trailing,
            imageMargin + (imageSize.width - textColumn.upperBound) * scale,
            accuracy: accuracy,
            "\(width)",
            line: line
        )
    }

    private func layout(width: CGFloat, x: CGFloat) -> Layout {
        var result = Layout()
        let view = AdaptiveImageScrollView(
            decorations: ImageDecorations(
                suraHeaders: [],
                ayahNumbers: [],
                drawsAyahNumbersAndSuraHeaders: false,
                chromeStyle: .green,
                wordFrames: WordFrameCollection(frames: []),
                textColumn: textColumn
            ),
            image: { pageImage },
            onScaleChange: { scale in
                result.scale = scale.scale
                result.xOffset = scale.xOffset
                result.yOffset = scale.yOffset
            },
            onGlobalFrameChange: { _ in },
            header: { TextInsetsProbe { result.insets = $0 } },
            footer: { Color.clear.frame(height: 20) }
        )
        // Ignores the window's safe area, so the space for the image is the page height less header and footer.
        let page = UIHostingController(rootView: view.ignoresSafeArea())
        let container = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width + x, height: pageHeight))
        window.rootViewController = container
        container.addChild(page)
        page.view.frame = CGRect(x: x, y: 0, width: width, height: pageHeight)
        container.view.addSubview(page.view)
        page.didMove(toParent: container)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        // Gives the measured sizes time to settle.
        let deadline = Date(timeIntervalSinceNow: 0.5)
        while Date() < deadline {
            window.layoutIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        return result
    }

    private var pageImage: UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = imageSize
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

private struct TextInsetsProbe: View {
    let onChange: (EdgeInsets) -> Void
    @Environment(\.quranPageTextInsets) private var insets

    var body: some View {
        Color.clear
            .frame(height: 20)
            .onChangeWithInitial(of: insets, perform: onChange)
    }
}
