//
//  MultipartTextLayoutTests.swift
//
//
//  Created by Mohamed Afifi on 2026-07-20.
//

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

    func test_wrappingParts_splitSurasIntoSeparateReferences() {
        let suras = Array(Quran.hafsMadani1405.suras[16 ... 18])
        let part = TextPart.suras(suras)

        let parts = part.wrappingParts

        XCTAssertEqual(parts.count, 5)
        XCTAssertEqual(parts.map { $0.rawValue(locale: english) }.joined(), part.rawValue(locale: english))
        for (index, part) in parts.enumerated() {
            if index.isMultiple(of: 2) {
                guard case .sura(let sura, false, .text) = part else {
                    return XCTFail("Expected a plain sura reference at \(index)")
                }
                XCTAssertEqual(sura, suras[index / 2])
            } else {
                XCTAssertEqual(part.rawValue(locale: english), " · ")
            }
        }
    }

    func test_view_wrapsSuraNamesOnlyBetweenSuras() async {
        guard #available(iOS 16.0, *) else { return }

        let widths: [CGFloat] = [60, 90, 100, 110, 130, 160]
        let heights = await MainActor.run {
            let suras = Array(Quran.hafsMadani1405.suras[16 ... 18])
            let wrapping: MultipartText = "\(suras: suras)"
            let separateReferences: MultipartText =
                "\(sura: suras[0]) · \(sura: suras[1]) · \(sura: suras[2])"
            return widths.map { width in
                (
                    fittingHeight(pinned(wrapping.view(ofSize: .body)), width: width),
                    fittingHeight(pinned(separateReferences.view(ofSize: .body)), width: width)
                )
            }
        }

        for (width, height) in zip(widths, heights) {
            XCTAssertEqual(height.0, height.1, accuracy: 1, "width \(width)")
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
