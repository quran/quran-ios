//
//  ReaderRail.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import AudioBannerFeature
import Localization
import NoorUI
#if QURAN_SYNC
import QuranAnnotations
#endif
import UIKit
import UIx

/// The reader's controls in the window's vertical bar, like iPhone Duo's in landscape: back, bookmark and More at
/// the top, and the audio controls at the bottom.
///
/// They're the navigation controller's bars, which the system moves to the vertical bar, so they show and hide with
/// the reader's bars, and pages make room for the column while they show. Windows without a vertical bar keep the
/// reader's own bars.
@MainActor
final class ReaderRail {
    /// A rail control that presents a popover.
    enum Control {
        case more
        case bookmark
    }

    // MARK: Lifecycle

    /// - Parameters:
    ///   - onModeChange: Called with `isActive` when the window gains or loses a vertical bar.
    ///   - onPopoverDismiss: Called after the rail dismisses a popover that lost its anchor.
    init(
        viewController: UIViewController,
        onMore: @escaping @MainActor @Sendable () -> Void,
        onBookmark: @escaping @MainActor @Sendable () -> Void,
        onModeChange: @escaping (Bool) -> Void,
        onPopoverDismiss: @escaping () -> Void
    ) {
        self.viewController = viewController
        self.onModeChange = onModeChange
        self.onPopoverDismiss = onPopoverDismiss
        moreItem = NavigationBarButton.secondary(image: .more, accessibilityLabel: l("button.more"), action: onMore)
        #if QURAN_SYNC
        bookmarkItem = NavigationBarButton.secondary(
            customImage: ReadingBookmarkIcon.image(style: .outline, badge: .ellipsis),
            accessibilityLabel: l("bookmarks.reading.choose.accessibility-label"),
            action: onBookmark
        )
        #else
        bookmarkItem = NavigationBarButton.secondary(image: .bookmarkOutline, accessibilityLabel: l("bookmarks.page.add"), action: onBookmark)
        #endif
        if #available(iOS 27.1, *) {
            for item in [moreItem, bookmarkItem] {
                item.axisBehavior = .verticalPreferred
            }
            viewController.navigationItem.largeTitleDisplayMode = .never
            // The reader never shows the tab bar, so the audio controls stay whenever the bar runs out of room.
            viewController.navigationItem.verticalBarCompressionBehavior = .prefersBarItems
            viewController.registerForTraitChanges(
                UITraitCollection.systemTraitsAffectingVerticalBarEdge + [UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]
            ) { [weak self] (_: UIViewController, _: UITraitCollection) in
                self?.update()
            }
        }
    }

    // MARK: Internal

    /// Whether the window has a vertical bar, so the rail replaces the reader's own bars.
    private(set) var isActive = false

    var isShown: Bool { isActive && !barsHidden }

    var audioToolbarItems: AudioToolbarItems? {
        didSet {
            audioToolbarItems?.onItemsChange = { [weak self] in self?.applyToolbarItems() }
            updateAudioItems()
        }
    }

    /// Which of the navigation controller's bars hide.
    static func hiddenBars(
        hasVerticalBar: Bool,
        barsHidden: Bool,
        hasAudioItems: Bool
    ) -> (navigationBar: Bool, toolbar: Bool) {
        let navigationBar = !hasVerticalBar || barsHidden
        return (navigationBar, navigationBar || !hasAudioItems)
    }

    /// Where a popover from a rail item points: a one-point line on the item's side facing the page, or on the rail's
    /// edge while the item isn't laid out. The arrow faces the rail, so the popover opens over the page.
    static func popoverAnchor(
        itemFrame: CGRect?,
        in bounds: CGRect,
        safeAreaInsets: UIEdgeInsets,
        side: UIRectEdge
    ) -> (rect: CGRect, arrowDirection: UIPopoverArrowDirection) {
        let isLeft = side == .left
        let arrowDirection: UIPopoverArrowDirection = isLeft ? .left : .right
        if let itemFrame, !itemFrame.isNull, !itemFrame.isEmpty, bounds.intersects(itemFrame) {
            let x = isLeft ? itemFrame.maxX : itemFrame.minX
            return (CGRect(x: x, y: itemFrame.minY, width: 1, height: itemFrame.height), arrowDirection)
        }
        let x = isLeft ? bounds.minX + safeAreaInsets.left : bounds.maxX - safeAreaInsets.right
        let height = max(1, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom)
        return (CGRect(x: x, y: bounds.minY + safeAreaInsets.top, width: 1, height: height), arrowDirection)
    }

    /// Switches between the rail and the reader's own bars when the window gains or loses a vertical bar.
    func update() {
        guard let viewController else {
            return
        }
        let wasActive = isActive
        isActive = viewController.traitCollection.hasVerticalBar
        updateAudioItems()
        guard isActive != wasActive else {
            return
        }
        dismissPopover()
        viewController.navigationItem.rightBarButtonItems = isActive ? [moreItem, bookmarkItem] : nil
        updateTitle()
        applyToolbarItems()
        onModeChange(isActive)
    }

    func setBarsHidden(_ hidden: Bool, animated: Bool) {
        barsHidden = hidden
        applyVisibility(animated: animated)
    }

    func applyVisibility(animated: Bool) {
        guard let viewController, let navigationController = viewController.navigationController,
              navigationController.topViewController === viewController
        else {
            return
        }
        let hidden = Self.hiddenBars(
            hasVerticalBar: isActive,
            barsHidden: barsHidden,
            hasAudioItems: !(audioToolbarItems?.items.isEmpty ?? true)
        )
        // BaseNavigationController takes the bar's visibility from the reader's `navigationBarHidden`.
        navigationController.setNavigationBarHidden(hidden.navigationBar, animated: animated)
        if navigationController.isToolbarHidden != hidden.toolbar {
            navigationController.setToolbarHidden(hidden.toolbar, animated: animated)
        }
    }

    /// A title in the vertical bar adds a large-title strip over the page.
    func updateTitle() {
        guard let viewController else {
            return
        }
        viewController.navigationItem.title = isActive ? nil : viewController.title
    }

    #if QURAN_SYNC
    func updateReadingBookmark(_ bookmark: PlacedReadingBookmark?) {
        bookmarkItem.configureReadingBookmark(bookmark, defaultTintColor: .label)
    }
    #else
    func updatePageBookmark(isBookmarked: Bool) {
        bookmarkItem.configurePageBookmark(isBookmarked: isBookmarked, defaultTintColor: .label)
    }
    #endif

    /// Presents a popover from the rail's control while it's active, otherwise from `ownBarItem`.
    func presentPopover(_ popover: UIViewController, from control: Control, ownBarItem: UIBarButtonItem) {
        guard let viewController else {
            return
        }
        self.popover = popover
        guard isActive, #available(iOS 17.0, *), let view = viewController.viewIfLoaded else {
            viewController.presentPopover(popover, pointingTo: ownBarItem)
            return
        }
        // UIKit places a vertical bar item's popover over the bar, ignoring arrow directions, and drops the item's
        // view when the bar rebuilds, so point from the reader's view instead.
        let item = control == .more ? moreItem : bookmarkItem
        let trailingSide: UIRectEdge = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        let anchor = Self.popoverAnchor(
            itemFrame: item.frame(in: view),
            in: view.bounds,
            safeAreaInsets: view.window?.safeAreaInsets ?? .zero,
            side: view.window?.traitCollection.verticalBarSide ?? trailingSide
        )
        viewController.presentPopover(popover, pointingTo: view, at: anchor.rect, permittedArrowDirections: anchor.arrowDirection)
    }

    /// Folding, unfolding and rotating move the rail, so its popover would point at nothing.
    func viewWillTransition() {
        if isActive {
            dismissPopover()
        }
    }

    // MARK: Private

    private weak var viewController: UIViewController?
    private let moreItem: UIBarButtonItem
    private let bookmarkItem: UIBarButtonItem
    private let onModeChange: (Bool) -> Void
    private let onPopoverDismiss: () -> Void
    private var barsHidden = false
    private weak var popover: UIViewController?

    private func dismissPopover() {
        guard let viewController, let popover, viewController.presentedViewController === popover, !popover.isBeingDismissed else {
            return
        }
        viewController.dismiss(animated: false)
        onPopoverDismiss()
    }

    private func updateAudioItems() {
        audioToolbarItems?.barTraits = isActive ? viewController?.traitCollection : nil
    }

    private func applyToolbarItems() {
        viewController?.setToolbarItems(isActive ? audioToolbarItems?.items : nil, animated: false)
        applyVisibility(animated: false)
    }
}
