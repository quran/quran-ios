//
//  MultipartTextLayoutTests.swift
//
//
//  Created by Mohamed Afifi on 2026-07-20.
//

import NoorFont
import QuranKit
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

final class MultipartTextLayoutTests: XCTestCase {
    func test_view_highlightedText_respectsInheritedLineLimit() async {
        guard #available(iOS 16.0, *) else { return }

        let value = String(repeating: "A long note that should be truncated. ", count: 10)
        let range = value.startIndex ..< value.index(value.startIndex, offsetBy: 6)
        let plain = MultipartText.text(value)
        let highlighted: MultipartText = "\(value, highlighting: [HighlightingRange(range, fontWeight: .heavy)])"

        let heights = await MainActor.run {
            let plainHeight = fittingHeight(
                plain.view(ofSize: .body)
                    .lineLimit(3)
            )
            let highlightedHeight = fittingHeight(
                highlighted.view(ofSize: .body)
                    .lineLimit(3)
            )
            return (plainHeight, highlightedHeight)
        }

        XCTAssertEqual(heights.1, heights.0, accuracy: 1)
    }

    func test_view_whenWrappingIsDisabled_keepsMultipartContentOnOneLine() async {
        guard #available(iOS 16.0, *) else { return }

        let heights = await MainActor.run {
            let sura = Quran.hafsMadani1405.suras[15]
            let text: MultipartText = "At \(ayah: sura.verses[29]) • Move here"

            let wrappingHeight = fittingHeight(
                text.view(ofSize: .footnote)
                    .lineLimit(1)
            )
            let singleLineHeight = fittingHeight(
                text.view(ofSize: .footnote, allowsWrapping: false)
            )

            return (wrappingHeight, singleLineHeight)
        }

        XCTAssertLessThan(heights.1, heights.0)
    }

    func test_view_wrapsSuraNamesOnlyBetweenSuras() async {
        guard #available(iOS 16.0, *) else { return }

        let widths: [CGFloat] = [60, 130, 260]
        let heights = await MainActor.run {
            if UIFont(name: "icomoon", size: 20) == nil {
                FontName.registerFonts()
            }
            let suras = Array(Quran.hafsMadani1405.suras[16 ... 18])
            return [SuraNameStyle.standard, .decorated].flatMap { style in
                let wrapping: MultipartText = "\(suras: suras, nameStyle: style)"
                let separateReferences: MultipartText = """
                \(sura: suras[0], nameStyle: style) · \(sura: suras[1], nameStyle: style) · \(sura: suras[2], nameStyle: style)
                """
                return widths.map { width in
                    (
                        "\(style) width \(width)",
                        fittingHeight(pinned(wrapping.view(ofSize: .body)), width: width),
                        fittingHeight(pinned(separateReferences.view(ofSize: .body)), width: width)
                    )
                }
            }
        }

        for (label, wrapping, separate) in heights {
            XCTAssertEqual(wrapping, separate, accuracy: 1, label)
        }
    }

    private let english = Locale(identifier: "en-CA")

    /// Fixes the locale and text size, so the widths that need an extra row don't move with simulator settings.
    private func pinned(_ content: some View) -> some View {
        content
            .environment(\.locale, english)
            .dynamicTypeSize(.large)
    }

    @MainActor
    private func fittingHeight(_ content: some View, width: CGFloat = 120) -> CGFloat {
        let controller = UIHostingController(rootView: content.frame(width: width, alignment: .leading))
        return controller.sizeThatFits(
            in: CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
    }
}
