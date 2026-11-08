import QuranAnnotations
import SwiftUI
import UIKit
import UIx
import XCTest
@testable import NoorUI

@MainActor
final class AyahMenuViewLayoutTests: XCTestCase {
    /// At Accessibility XL the menu asked its popover for about 517 points, wider than the screen,
    /// so UIKit narrowed the popover and the menu ran off both edges.
    func test_menu_asksForNoMoreThanThePopoverWidthAtLargerTextSizes() {
        guard #available(iOS 17.0, *) else { return }
        for size in [UIContentSizeCategory.extraExtraExtraLarge, .accessibilityExtraLarge, .accessibilityExtraExtraExtraLarge] {
            XCTAssertLessThanOrEqual(preferredWidth(at: size), popoverWidth + 0.5, "at \(size.rawValue)")
        }
    }

    /// At the default text size the popover still hugs the menu's one-line rows.
    func test_menu_keepsItsOneLineWidthAtTheDefaultTextSize() {
        guard #available(iOS 17.0, *) else { return }
        let width = preferredWidth(at: .large)

        XCTAssertLessThan(width, popoverWidth)
        XCTAssertEqual(width, preferredWidth(at: .large, offeredWidth: 1000), accuracy: 0.5)
    }

    /// The popover then gives the menu the pixel-rounded width it asked for. No row may move its subtitle under
    /// its title there, which would make the menu taller.
    func test_menu_keepsItsOneLineRowsAtTheWidthItAskedFor() {
        guard #available(iOS 17.0, *) else { return }
        let sizes = preferredSizes(at: .large)

        XCTAssertEqual(sizes.atReportedWidth.width, sizes.asked.width, accuracy: 0.5)
        XCTAssertEqual(sizes.atReportedWidth.height, sizes.asked.height, accuracy: 0.5)
    }

    #if !QURAN_SYNC
    /// At Accessibility XL the five highlight colors needed about 446 points in one row, wider than the screen.
    func test_highlightColors_fitThePopoverWidthAtLargerTextSizes() {
        guard #available(iOS 17.0, *) else { return }
        for size in [DynamicTypeSize.xxxLarge, .accessibility3, .accessibility5] {
            XCTAssertLessThanOrEqual(highlightColorsSize(at: size, width: popoverWidth).width, popoverWidth, "at \(size)")
        }
    }

    /// The colors replace a menu that can be narrower than them, so at the default text size they keep one row
    /// and the popover widens to fit them.
    func test_highlightColors_stayOnOneRowAtTheDefaultTextSize() {
        guard #available(iOS 17.0, *) else { return }
        let oneRow = highlightColorsSize(at: .large, width: .greatestFiniteMagnitude)
        let inNarrowerMenu = highlightColorsSize(at: .large, width: oneRow.width - 40)

        XCTAssertEqual(inNarrowerMenu.width, oneRow.width, accuracy: 0.5)
        XCTAssertEqual(inNarrowerMenu.height, oneRow.height, accuracy: 0.5)
    }
    #endif

    // MARK: Private

    private let popoverWidth = 320.0

    @available(iOS 17.0, *)
    private func preferredWidth(at size: UIContentSizeCategory, offeredWidth: CGFloat? = nil) -> CGFloat {
        preferredSizes(at: size, offeredWidth: offeredWidth).asked.width
    }

    /// Hosts the menu like the ayah menu popover does and returns the size it asks the popover for. Then, like the
    /// popover, gives the menu that width rounded down to pixels, and returns the size it asks for there.
    ///
    /// The row titles come from the test process's localization, so these sizes assume it runs in English, like
    /// the other layout tests.
    @available(iOS 17.0, *)
    private func preferredSizes(
        at size: UIContentSizeCategory,
        offeredWidth: CGFloat? = nil
    ) -> (asked: CGSize, atReportedWidth: CGSize) {
        let container = UIViewController()
        container.traitOverrides.preferredContentSizeCategory = size
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = container
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let menu = AutoUpdatingPreferredContentSizeHostingController(
            rootView: AyahMenuView(dataObject: dataObject)
                .environment(\.locale, Locale(identifier: "en-CA"))
                .typesettingLanguage(Locale.Language(identifier: "en"))
        )
        container.addChild(menu)
        menu.view.frame = CGRect(x: 0, y: 0, width: offeredWidth ?? popoverWidth, height: 600)
        container.view.addSubview(menu.view)
        menu.didMove(toParent: container)
        // The menu reports its size a run loop after layout.
        let deadline = Date(timeIntervalSinceNow: 2)
        while menu.preferredContentSize == .zero, Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        let asked = menu.preferredContentSize

        let scale = window.screen.scale
        menu.view.frame.size.width = (asked.width * scale).rounded(.down) / scale
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        return (asked, menu.preferredContentSize)
    }

    #if !QURAN_SYNC
    @available(iOS 17.0, *)
    private func highlightColorsSize(at size: DynamicTypeSize, width: CGFloat) -> CGSize {
        UIHostingController(
            rootView: NoteCircles(selectedColor: .green, tapped: { _ in })
                .environment(\.locale, Locale(identifier: "en-CA"))
                .typesettingLanguage(Locale.Language(identifier: "en"))
                .dynamicTypeSize(size)
        )
        .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }
    #endif

    private var dataObject: AyahMenuUI.DataObject {
        #if QURAN_SYNC
        let actions = AyahMenuUI.Actions(
            play: {},
            repeatVerses: {},
            bookmark: {},
            addNote: {},
            deleteNote: {},
            showTranslation: {},
            copy: {},
            share: {},
            showReadingBookmarkMenu: {}
        )
        return AyahMenuUI.DataObject(
            highlightingColor: .green,
            state: .noHighlight,
            bookmarkTitle: "Save Ayah...",
            notesTitle: "Notes",
            playSubtitle: "to the end of Juz'",
            repeatSubtitle: "selected verse",
            actions: actions,
            isTranslationView: false,
            readingBookmarkState: .available(bookmark: nil, subtitle: "Set here", showsNewBadge: true)
        )
        #else
        let actions = AyahMenuUI.Actions(
            play: {},
            repeatVerses: {},
            highlight: { _ in },
            addNote: {},
            deleteNote: {},
            showTranslation: {},
            copy: {},
            share: {}
        )
        return AyahMenuUI.DataObject(
            highlightingColor: .green,
            state: .highlighted,
            playSubtitle: "to the end of Juz'",
            repeatSubtitle: "selected verse",
            actions: actions,
            isTranslationView: false
        )
        #endif
    }
}
