//
//  NoorListItemLayoutTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import NoorFont
import QuranKit
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

final class NoorListItemLayoutTests: XCTestCase {
    @MainActor
    func test_textAccessory_doesNotWrapSuraTitleThatFits() {
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
        let sura = Quran.hafsMadani1405.suras[28]
        let title: MultipartText = "\(sura.localizedSuraNumber). \(sura: sura)"
        let subtitle = NoorListItem.Subtitle(text: "The Spider · Makki · 69 verses", location: .bottom)

        let heightWithAccessory = fittingHeight(
            NoorListItem(title: title, subtitle: subtitle, accessory: .text("396"))
        )
        let heightWithoutAccessory = fittingHeight(
            NoorListItem(title: title, subtitle: subtitle)
        )

        XCTAssertEqual(heightWithAccessory, heightWithoutAccessory, accuracy: 1)
    }

    @MainActor
    func test_trailingSubtitle_staysBesideTitleAtRegularSizes() {
        let rowHeight = fittingHeight(
            NoorListItem(
                title: "App Icon",
                subtitle: .init(text: "QuranEngine", location: .trailing),
                accessory: .disclosureIndicator
            ),
            dynamicTypeSize: .large
        )
        let titleHeight = fittingHeight(
            NoorListItem(title: "App Icon", accessory: .disclosureIndicator),
            dynamicTypeSize: .large
        )

        XCTAssertEqual(rowHeight, titleHeight, accuracy: 1)
    }

    @MainActor
    func test_trailingSubtitle_movesUnderTitleAtAccessibilitySizes() {
        let title: MultipartText = "App Icon"
        let value: MultipartText = "QuranEngine Nightfall"

        let rowHeight = fittingHeight(
            NoorListItem(
                title: title,
                subtitle: .init(text: value, location: .trailing),
                accessory: .disclosureIndicator
            ),
            dynamicTypeSize: .accessibility5
        )
        // Each text wraps as it would with the row to itself: neither squeezes the other.
        let titleHeight = fittingHeight(
            NoorListItem(title: title, accessory: .disclosureIndicator),
            dynamicTypeSize: .accessibility5
        )
        let valueHeight = fittingHeight(
            NoorListItem(title: value, accessory: .disclosureIndicator),
            dynamicTypeSize: .accessibility5
        )

        // Allow for the VStack spacing between the texts, which grows with the text size.
        XCTAssertEqual(rowHeight, titleHeight + valueHeight, accuracy: titleHeight / 2)
    }

    @MainActor
    func test_pageNumberAccessory_staysBesideTitleAtAccessibilitySizes() {
        let rowHeight = fittingHeight(
            NoorListItem(title: "Yusuf", accessory: .text("235")),
            dynamicTypeSize: .accessibility5
        )
        let titleHeight = fittingHeight(
            NoorListItem(title: "Yusuf"),
            dynamicTypeSize: .accessibility5
        )

        XCTAssertEqual(rowHeight, titleHeight, accuracy: 1)
    }

    @MainActor
    private func fittingHeight(_ content: some View, dynamicTypeSize: DynamicTypeSize = .large) -> CGFloat {
        let width: CGFloat = 345
        let controller = UIHostingController(
            rootView: content
                .frame(width: width)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
        )
        return controller.sizeThatFits(
            in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        ).height
    }
}
