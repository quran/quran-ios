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

    @MainActor
    private func fittingHeight(_ content: some View) -> CGFloat {
        let width: CGFloat = 120
        let controller = UIHostingController(rootView: content.frame(width: width, alignment: .leading))
        return controller.sizeThatFits(
            in: CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
    }
}
