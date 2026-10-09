//
//  QuranVerseNumberTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-09.
//

#if QURAN_SYNC
import QuranAnnotations
#endif
import QuranKit
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class QuranVerseNumberTests: XCTestCase {
    func test_inlineSize_matchesTheRenderedCapsule() {
        assertInlineSizeMatchesRenderedCapsule(legibilityWeight: .regular)
    }

    func test_inlineSize_withBoldText_matchesTheRenderedCapsule() {
        assertInlineSizeMatchesRenderedCapsule(legibilityWeight: .bold)
    }

    // MARK: Private

    private func assertInlineSizeMatchesRenderedCapsule(legibilityWeight: LegibilityWeight, file: StaticString = #filePath, line: UInt = #line) {
        let verses = [Quran.hafsMadani1405.firstVerse, Quran.hafsMadani1405.suras[1].verses[254]]
        let sizes: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge, .accessibility2]
        for verse in verses {
            for (variant, verseNumber) in makeVerseNumbers(verse: verse).enumerated() {
                for dynamicTypeSize in sizes {
                    let computed = verseNumber.inlineSize(dynamicTypeSize: dynamicTypeSize, legibilityWeight: legibilityWeight)
                    let rendered = fittingSize(
                        verseNumber
                            .inline(size: computed, maximumHorizontalOutset: 4)
                            .environment(\.dynamicTypeSize, dynamicTypeSize)
                            .environment(\.legibilityWeight, legibilityWeight)
                    )
                    let context = "\(verse.nonLocalizedDescription) variant \(variant) \(dynamicTypeSize) \(legibilityWeight)"
                    XCTAssertEqual(computed.width, rendered.width, accuracy: 1, context, file: file, line: line)
                    XCTAssertEqual(computed.height, rendered.height, accuracy: 1, context, file: file, line: line)
                }
            }
        }
    }

    /// The verse's capsule, with every annotation-badge layout in sync builds.
    private func makeVerseNumbers(verse: AyahNumber) -> [QuranVerseNumber] {
        #if QURAN_SYNC
        let annotationSets: [Set<AyahAnnotation>] = [[], [.note], [.readingBookmark(.teal), .collection, .note]]
        return annotationSets.map { QuranVerseNumber(verse: verse, annotations: $0, onTapped: { _ in }) }
        #else
        return [QuranVerseNumber(verse: verse)]
        #endif
    }

    private func fittingSize(_ content: some View) -> CGSize {
        let controller = UIHostingController(rootView: content.fixedSize())
        return controller.sizeThatFits(
            in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
    }
}
