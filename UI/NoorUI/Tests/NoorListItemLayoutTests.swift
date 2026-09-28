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
    private func fittingHeight(_ content: some View) -> CGFloat {
        let width: CGFloat = 345
        let controller = UIHostingController(rootView: content.frame(width: width))
        return controller.sizeThatFits(
            in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        ).height
    }
}
