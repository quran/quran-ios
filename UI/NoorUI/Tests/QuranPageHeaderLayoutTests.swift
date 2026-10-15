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

    private func idealSize(of text: MultipartText, _ size: DynamicTypeSize) -> CGSize {
        let content = text.view(ofSize: .footnote, allowsWrapping: false).fixedSize()
        return UIHostingController(rootView: pinned(content, size))
            .sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    private func suraNamesSize(width: CGFloat, _ size: DynamicTypeSize) -> CGSize {
        UIHostingController(rootView: pinned(QuranPageHeaderSuraNames(suras: suras, size: .footnote), size))
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
