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

    func test_view_rightToLeftText_keepsTrailingSpaceBeforeNextPart() async {
        guard #available(iOS 16.0, *) else { return }

        let widths = await MainActor.run { spacedAndUnspacedReferenceWidths(allowsWrapping: true) }

        XCTAssertEqual(widths.spaced - widths.unspaced, widths.space, accuracy: 1)
    }

    func test_view_rightToLeftText_whenWrappingIsDisabled_keepsTrailingSpaceBeforeNextPart() async {
        let widths = await MainActor.run { spacedAndUnspacedReferenceWidths(allowsWrapping: false) }

        XCTAssertEqual(widths.spaced - widths.unspaced, widths.space, accuracy: 1)
    }

    func test_view_rightToLeftSentenceEndingInSpace_wrapsWithinWidth() async {
        guard #available(iOS 16.0, *) else { return }

        let width: CGFloat = 120
        let sizes = await MainActor.run {
            let ayah = Quran.hafsMadani1405.suras[1].verses[254]
            let reference: MultipartText = "\(ayah: ayah, nameStyle: .text)"
            let sentence = String(repeating: "هذه جملة طويلة ", count: 6)
            let text = MultipartText.format("\(sentence)%@", arguments: [reference])
            return (
                wrapped: fittingArabicSize(text.view(ofSize: .footnote), width: width),
                line: fittingArabicSize(Text("عند").font(.footnote), width: width)
            )
        }

        XCTAssertLessThanOrEqual(sizes.wrapped.width, width)
        XCTAssertGreaterThan(sizes.wrapped.height, sizes.line.height * 3)
    }

    /// Mirrors `"bookmarks.reading.location" = "عند %@"`, so the plain part ends with a space.
    @MainActor
    private func spacedAndUnspacedReferenceWidths(allowsWrapping: Bool) -> (spaced: CGFloat, unspaced: CGFloat, space: CGFloat) {
        let ayah = Quran.hafsMadani1405.suras[1].verses[254]
        let reference: MultipartText = "\(ayah: ayah, nameStyle: .text)"
        let spaced = MultipartText.format("عند %@", arguments: [reference])
        let unspaced = MultipartText.format("عند%@", arguments: [reference])
        return (
            fittingArabicWidth(spaced.view(ofSize: .footnote, allowsWrapping: allowsWrapping)),
            fittingArabicWidth(unspaced.view(ofSize: .footnote, allowsWrapping: allowsWrapping)),
            fittingArabicWidth(Text(" ").font(.footnote))
        )
    }

    @MainActor
    private func fittingArabicWidth(_ content: some View) -> CGFloat {
        let controller = UIHostingController(
            rootView: content
                .fixedSize()
                .environment(\.locale, Locale(identifier: "ar"))
                .environment(\.layoutDirection, .rightToLeft)
                .dynamicTypeSize(.large)
        )
        return controller.sizeThatFits(
            in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        ).width
    }

    @MainActor
    private func fittingArabicSize(_ content: some View, width: CGFloat) -> CGSize {
        let controller = UIHostingController(
            rootView: content
                .environment(\.locale, Locale(identifier: "ar"))
                .environment(\.layoutDirection, .rightToLeft)
                .dynamicTypeSize(.large)
        )
        return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    @MainActor
    private func fittingHeight(_ content: some View, width: CGFloat = 120) -> CGFloat {
        let controller = UIHostingController(rootView: content.frame(width: width, alignment: .leading))
        return controller.sizeThatFits(
            in: CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
    }
}
