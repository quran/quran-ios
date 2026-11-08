#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import SwiftUI
import UIKit
import UIx
import XCTest
@testable import ReadingBookmarkMenuFeature

@MainActor
final class ReadingBookmarkMenuLayoutTests: XCTestCase {
    /// A long reference beside the action used to push the row past a 320-point popover.
    func test_moveHereRow_fitsThePopoverWidth() {
        guard #available(iOS 17.0, *) else { return }
        let row = ReadingBookmarkMenuRow(
            item: .init(slot: .orange, name: nil, placement: .ayah(Quran.hafsMadani1405.suras[59].verses[12])),
            target: .page(Quran.hafsMadani1405.pages[1]),
            isFirstRun: false,
            name: .constant(""),
            isEnabled: true,
            editMode: .inactive,
            save: { true },
            select: {}
        )
        XCTAssertEqual(row.action, .moveHere)

        for size in [DynamicTypeSize.xxxLarge, .accessibility3, .accessibility5] {
            let width = UIHostingController(
                rootView: row
                    .environment(\.locale, Locale(identifier: "en-CA"))
                    .typesettingLanguage(Locale.Language(identifier: "en"))
                    .dynamicTypeSize(size)
            )
            .sizeThatFits(in: CGSize(width: popoverWidth, height: .greatestFiniteMagnitude))
            .width

            XCTAssertLessThanOrEqual(width, popoverWidth, "at \(size)")
        }
    }

    /// At Accessibility XL the menu asked its popover for about 700 points, wider than the screen.
    func test_menu_asksForThePopoverWidthAtLargerTextSizes() {
        guard #available(iOS 17.0, *) else { return }
        for size in [UIContentSizeCategory.large, .extraExtraExtraLarge, .accessibilityExtraLarge] {
            XCTAssertEqual(preferredWidth(at: size), popoverWidth, accuracy: 0.5, "at \(size.rawValue)")
        }
    }

    func test_firstRunMenu_asksForThePopoverWidthAtAccessibilitySizes() {
        guard #available(iOS 17.0, *) else { return }
        for size in [UIContentSizeCategory.accessibilityExtraLarge, .accessibilityExtraExtraExtraLarge] {
            XCTAssertEqual(preferredWidth(at: size, isFirstRun: true), popoverWidth, accuracy: 0.5, "at \(size.rawValue)")
        }
    }

    // MARK: Private

    private let popoverWidth = 320.0

    /// Hosts the menu like a popover does, then returns the width it asks the popover for.
    @available(iOS 17.0, *)
    private func preferredWidth(at size: UIContentSizeCategory, isFirstRun: Bool = false) -> CGFloat {
        let container = UIViewController()
        container.traitOverrides.preferredContentSizeCategory = size
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = container
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let menu = AutoUpdatingPreferredContentSizeHostingController(rootView: menuContent(isFirstRun: isFirstRun))
        container.addChild(menu)
        menu.view.frame = CGRect(x: 0, y: 0, width: popoverWidth, height: 600)
        container.view.addSubview(menu.view)
        menu.didMove(toParent: container)
        // The menu reports its size a run loop after layout.
        let deadline = Date(timeIntervalSinceNow: 2)
        while menu.preferredContentSize == .zero, Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        return menu.preferredContentSize.width
    }

    private func menuContent(isFirstRun: Bool) -> some View {
        let page = Quran.hafsMadani1405.pages[1]
        let items: [ReadingBookmarkMenuViewModel.Item] = isFirstRun
            ? ReadingBookmarkSlot.allCases.map { .init(slot: $0, name: nil, placement: .unplaced) }
            : [
                .init(slot: .teal, name: nil, placement: .page(page)),
                .init(slot: .orange, name: nil, placement: .ayah(Quran.hafsMadani1405.suras[17].verses[9])),
                .init(slot: .red, name: nil, placement: .unplaced),
            ]
        return ReadingBookmarkMenuContent(
            error: .constant(nil),
            draftNames: .constant([:]),
            editMode: .constant(.inactive),
            items: items,
            target: .page(page),
            isFirstRun: isFirstRun,
            isEnabled: true,
            start: {},
            saveNames: { _ in true },
            select: { _ in }
        )
        .environment(\.locale, Locale(identifier: "en-CA"))
    }
}
#endif
