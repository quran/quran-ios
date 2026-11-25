//
//  MultipartTextBaselineTests.swift
//

import NoorFont
import QuranKit
import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

/// A line shares one baseline when its first and last text baselines coincide: stacks report the topmost
/// baseline of their parts as the first and the bottommost as the last.
@MainActor
final class MultipartTextBaselineTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    func test_decoratedGlyph_sharesTheBaselineOfTheTextAroundIt() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Measuring baselines needs Layout") }
        // Mirrors the Arabic reading-bookmark toast, "تم حفظ علامة موضع القراءة عند %@".
        let toast = MultipartText.format("تم حفظ علامة موضع القراءة عند %@", arguments: ["\(ayah: ayah)"])
        let indoPakAyah = Quran.hafsIndoPak.suras[1].verses[254]
        let indoPakToast = MultipartText.format("تم حفظ علامة موضع القراءة عند %@", arguments: ["\(ayah: indoPakAyah)"])
        let lines: [(String, MultipartText, Locale)] = [
            ("toast", toast, arabic),
            ("IndoPak toast", indoPakToast, arabic),
            ("IndoPak decorated", "at \(ayah: indoPakAyah, nameStyle: .decorated)", english),
            ("sura", "عند \(sura: ayah.sura)", arabic),
            ("decorated", "at \(ayah: ayah, nameStyle: .decorated)", english),
            ("suras", "\(suras: suras, nameStyle: .decorated)", arabic),
        ]
        for (label, text, locale) in lines {
            for size in [MultipartText.FontSize.footnote, .title3] {
                for allowsWrapping in [true, false] {
                    let line = textBaselines(of: text.view(ofSize: size, allowsWrapping: allowsWrapping), locale: locale)
                    let message = "\(label) \(size) allowsWrapping: \(allowsWrapping)"

                    // A view without text reports its bottom as both baselines.
                    XCTAssertLessThan(line.first, line.height - 1, message)
                    XCTAssertEqual(line.first, line.last, accuracy: 0.5, message)
                }
            }
        }
    }

    func test_decoratedGlyph_keepsRoomAboveItsBaselineForItsInk() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Measuring baselines needs Layout") }
        let font = UIFont(.suraNames, size: 100)
        let inkTopPerAscender = CTFontGetBoundingBox(font as CTFont).maxY / font.ascender
        let glyph = QuranReference.sura(ayah.sura).rawValue(locale: arabic)
        for size in [MultipartText.FontSize.footnote, .title3] {
            let ascender = textBaselines(of: Text(glyph).font(size.suraFont), locale: arabic).first
            let reference = textBaselines(of: MultipartText("\(sura: ayah.sura)").view(ofSize: size), locale: arabic)

            XCTAssertGreaterThanOrEqual(reference.first, ascender * inkTopPerAscender, "\(size)")
        }
    }

    /// Centred contexts, like the translation sura banner, centre a glyph alone on its ink, which sits low in its line box.
    func test_decoratedGlyphAlone_centresOnItsInk() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Measuring baselines needs Layout") }
        let glyph = QuranReference.sura(ayah.sura).rawValue(locale: arabic)
        for size in [MultipartText.FontSize.footnote, .title3] {
            let em = textBaselines(of: Text(glyph).font(size.suraFont), locale: arabic).height
            let name: MultipartText = "\(sura: ayah.sura, nameStyle: .decorated)"
            let line = textBaselines(of: name.view(ofSize: size, allowsWrapping: false), locale: arabic)

            XCTAssertEqual(line.nameCenter, line.first - em * QuranReference.decoratedGlyphInkCenter, accuracy: 0.34, "\(size)")
        }
    }

    /// Beside a localized name, a glyph centres on the name's text, as a line of text would.
    func test_decoratedGlyphBesideAName_centresOnTheName() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Measuring baselines needs Layout") }
        for size in [MultipartText.FontSize.footnote, .title3] {
            let text = textBaselines(of: Text("Al-Baqarah").font(size.plainFont), locale: english)
            let name: MultipartText = "\(sura: ayah.sura, nameStyle: .decorated)"
            let line = textBaselines(of: name.view(ofSize: size, allowsWrapping: false), locale: english)

            XCTAssertEqual(line.first - line.nameCenter, text.first - text.height / 2, accuracy: 0.34, "\(size)")
        }
    }

    // MARK: Private

    private let english = Locale(identifier: "en")
    private let arabic = Locale(identifier: "ar")
    private let ayah = Quran.hafsMadani1405.suras[1].verses[254]
    private let suras = Array(Quran.hafsMadani1405.suras[16 ... 18])

    @available(iOS 16.0, *)
    private func textBaselines(
        of content: some View,
        locale: Locale
    ) -> (first: CGFloat, last: CGFloat, height: CGFloat, nameCenter: CGFloat) {
        let probe = BaselineProbe()
        let pinned = BaselineProbeLayout(probe: probe) {
            content
        }
        .environment(\.locale, locale)
        .environment(\.layoutDirection, locale.isRightToLeft ? .rightToLeft : .leftToRight)
        .dynamicTypeSize(.large)
        let controller = if #available(iOS 17.0, *) {
            UIHostingController(rootView: AnyView(pinned.typesettingLanguage(locale.language)))
        } else {
            UIHostingController(rootView: AnyView(pinned))
        }
        _ = controller.sizeThatFits(in: CGSize(width: 2000, height: CGFloat.greatestFiniteMagnitude))
        return (probe.first ?? .nan, probe.last ?? .nan, probe.height ?? .nan, probe.nameCenter ?? .nan)
    }
}

private final class BaselineProbe {
    var first: CGFloat?
    var last: CGFloat?
    var height: CGFloat?
    var nameCenter: CGFloat?
}

/// Records its only subview's first and last text baselines, its height, and its sura-name centre.
@available(iOS 16.0, *)
private struct BaselineProbeLayout: Layout {
    let probe: BaselineProbe

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let dimensions = subviews[0].dimensions(in: proposal)
        probe.first = dimensions[VerticalAlignment.firstTextBaseline]
        probe.last = dimensions[VerticalAlignment.lastTextBaseline]
        probe.height = dimensions.height
        probe.nameCenter = dimensions[VerticalAlignment.decoratedSuraNameCenter]
        return CGSize(width: dimensions.width, height: dimensions.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}
