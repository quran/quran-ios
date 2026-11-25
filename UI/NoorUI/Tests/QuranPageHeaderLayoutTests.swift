//
//  QuranPageHeaderLayoutTests.swift
//

import NoorFont
import QuranKit
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class QuranPageHeaderLayoutTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    /// In Arabic a one-sura header shows a glyph alone, and a two-sura header puts " · " between glyphs. Pages
    /// rescale as you swipe if the two differ.
    func test_header_inArabic_keepsItsHeightWhateverTheSuraCount() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Typesetting languages need iOS 17") }
        let pages = Quran.hafsMadani1405.pages
        let oneSura = try XCTUnwrap(pages.first { $0.suras.count == 1 })
        let twoSuras = try XCTUnwrap(pages.first { $0.suras.count == 2 })
        for size in [DynamicTypeSize.large, .xxxLarge] {
            XCTAssertEqual(arabicHeaderHeight(oneSura, size), arabicHeaderHeight(twoSuras, size), accuracy: 0.1, "\(size)")
        }
    }

    func test_header_keepsTheDecoratedLineHeight() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        XCTAssertGreaterThan(
            idealSize(of: "\(suras: suras, nameStyle: .decorated)", .large).height,
            idealSize(of: "\(suras: suras)", .large).height + 1
        )
        let cases: [(CGFloat, DynamicTypeSize)] = [(600, .large), (300, .large), (430, .xxxLarge)]
        for (width, size) in cases {
            XCTAssertEqual(
                headerHeight(width: width, size),
                idealSize(of: "\(suras: suras, nameStyle: .decorated)", size).height,
                accuracy: 0.5,
                "\(width) \(size)"
            )
        }
    }

    func test_suraNames_whenDecoratedNamesFit_showsThem() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        let decorated = idealSize(of: "\(suras: suras, nameStyle: .decorated)", .large)

        XCTAssertEqual(suraNamesSize(width: 600, .large).width, decorated.width, accuracy: 0.5)
    }

    func test_suraNames_whenDecoratedNamesDontFit_fallBackToStandardNamesOnOneLine() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        let cases: [(CGFloat, DynamicTypeSize)] = [(250, .large), (300, .xxxLarge)]
        for (width, size) in cases {
            let standard = idealSize(of: "\(suras: suras)", size)
            let decorated = idealSize(of: "\(suras: suras, nameStyle: .decorated)", size)
            let suraNames = suraNamesSize(width: width, size)

            XCTAssertEqual(suraNames.width, standard.width, accuracy: 0.5, "\(width) \(size)")
            XCTAssertEqual(suraNames.height, decorated.height, accuracy: 0.5, "\(width) \(size)")
        }
    }

    func test_insetHeader_whenDecoratedNamesFitInset_keepsTheInset() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        let (width, totals) = rowInsetTotals()
        let insets = horizontalInsets(totaling: totals.decorated)

        let subject = try render(header, width: width, insets: insets)

        XCTAssertEqual(subject, try render(header.padding(insets), width: width))
    }

    func test_insetHeader_whenOnlyStandardNamesFitInset_keepsTheInsetWithStandardNames() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        let widths = rowWidths(.large)
        XCTAssertGreaterThan(widths.decorated - widths.standard, 10)
        // Decorated names fit the full width, but only standard names fit inside the inset.
        let (width, totals) = rowInsetTotals()
        let insets = horizontalInsets(totaling: totals.standard)

        let subject = try render(header, width: width, insets: insets)

        XCTAssertEqual(subject, try render(header.padding(insets), width: width))
    }

    func test_insetHeader_whenNothingFitsInset_fallsBackToTheFullWidthHeader() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        let (width, totals) = rowInsetTotals()

        let subject = try render(header, width: width, insets: horizontalInsets(totaling: totals.fullWidth))

        XCTAssertEqual(subject, try render(header, width: width))
    }

    /// The insets follow the image, which follows the header's size, so they must never resize the header.
    func test_insetHeader_keepsTheFullWidthHeaderSize() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("ViewThatFits needs iOS 16") }
        // Page 215's logged insets made the inset row overflow its width; `sizeThatFits` rounds that up a pixel.
        let page215 = QuranPageHeader(quarterName: "Juz' 11", suras: Quran.hafsMadani1405.pages[214].suras)
        let page215Insets = EdgeInsets(top: 0, leading: 24.150000000000002, bottom: 0, trailing: 19.40625)
        XCTAssertEqual(headerSize(page215, width: 414, insets: page215Insets), headerSize(page215, width: 414))

        // Guards each row choice too.
        let (width, totals) = rowInsetTotals()
        for total in [totals.decorated, totals.standard, totals.fullWidth] {
            let insets = horizontalInsets(totaling: total)
            XCTAssertEqual(headerSize(header, width: width, insets: insets), headerSize(header, width: width), "\(total)")
        }
    }

    // MARK: Private

    private let suras = Quran.hafsMadani1405.pages[603].suras
    private let quarterName = "Juz' 30"

    /// Fixes the locale and text size, so the widths that fit don't move with simulator settings.
    private func pinned(_ content: some View, _ size: DynamicTypeSize) -> some View {
        content
            .font(.footnote)
            .environment(\.locale, Locale(identifier: "en"))
            .environment(\.layoutDirection, .leftToRight)
            .dynamicTypeSize(size)
    }

    @available(iOS 17.0, *)
    private func arabicHeaderHeight(_ page: Page, _ size: DynamicTypeSize) -> CGFloat {
        let width: CGFloat = 400
        let header = QuranPageHeader(quarterName: "الجزء ١", suras: page.suras)
            .frame(width: width)
            .font(.footnote)
            .environment(\.locale, Locale(identifier: "ar"))
            .environment(\.layoutDirection, .rightToLeft)
            .dynamicTypeSize(size)
            .typesettingLanguage(Locale.Language(identifier: "ar"))
        return UIHostingController(rootView: header)
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
            .height
    }

    private func idealSize(of text: MultipartText, _ size: DynamicTypeSize) -> CGSize {
        let content = text.view(ofSize: .footnote, allowsWrapping: false).fixedSize()
        return UIHostingController(rootView: pinned(content, size))
            .sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    private func suraNamesSize(width: CGFloat, _ size: DynamicTypeSize) -> CGSize {
        UIHostingController(rootView: pinned(QuranPageHeaderSuraNames(suras: suras, size: .footnote), size))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    private var header: QuranPageHeader {
        QuranPageHeader(quarterName: quarterName, suras: suras)
    }

    /// The header row's ideal widths with decorated and with standard sura names.
    private func rowWidths(_ size: DynamicTypeSize) -> (decorated: CGFloat, standard: CGFloat) {
        // With no width proposed, the sura names report their decorated width.
        let decorated = UIHostingController(rootView: pinned(header.fixedSize(), size))
            .sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
            .width
        let decoratedNames = idealSize(of: "\(suras: suras, nameStyle: .decorated)", size).width
        let standardNames = idealSize(of: "\(suras: suras)", size).width
        return (decorated, decorated - decoratedNames + standardNames)
    }

    /// A header width the decorated row fits, and inset totals that leave room for only the decorated row, only
    /// the standard row, or neither.
    private func rowInsetTotals() -> (width: CGFloat, totals: (decorated: CGFloat, standard: CGFloat, fullWidth: CGFloat)) {
        let widths = rowWidths(.large)
        let width = widths.decorated + 20
        return (width, (10, width - (widths.standard + widths.decorated) / 2, width - (widths.standard - 10)))
    }

    private func horizontalInsets(totaling total: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: total / 2, bottom: 0, trailing: total / 2)
    }

    @available(iOS 16.0, *)
    private func render(_ content: some View, width: CGFloat, insets: EdgeInsets = EdgeInsets()) throws -> Data {
        let renderer = ImageRenderer(
            content: pinned(content.environment(\.quranPageTextInsets, insets).frame(width: width), .large)
        )
        renderer.scale = 2
        return try XCTUnwrap(renderer.uiImage?.pngData())
    }

    private func headerSize(_ header: QuranPageHeader, width: CGFloat, insets: EdgeInsets = EdgeInsets()) -> CGSize {
        let content = pinned(header.environment(\.quranPageTextInsets, insets), .large)
        return UIHostingController(rootView: content)
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    /// The header's height without its bottom spacing.
    private func headerHeight(width: CGFloat, _ size: DynamicTypeSize) -> CGFloat {
        let header = QuranPageHeader(quarterName: quarterName, suras: suras)
        let controller = UIHostingController(rootView: pinned(header.frame(width: width), size))
        let height = controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return height - ContentDimension.interSpacing
    }
}
