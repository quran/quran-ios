//
//  ToastPlacement.swift
//
//
//  Created by Mohamed Afifi on 2026-11-08.
//

import CoreGraphics

/// Where a toast sits so it clears the bars at the bottom of its window: the presenting screen's own bars,
/// like a tab bar, and the bars that keep toasts above them, like the reader's audio bar.
struct ToastPlacement {
    /// A bar that keeps toasts above it.
    struct Bar {
        /// The bar's frame in the window.
        var frame: CGRect
        /// Whether the bar and the views it's in show.
        var isVisible = true
        /// The frames, in the window, of the screens presented above the bar's screen, like a sheet or a popover.
        var screensAbove: [CGRect] = []
    }

    /// The window's size.
    var windowSize: CGSize
    /// The window's bottom safe-area inset, like the home indicator's.
    var windowBottomInset: CGFloat
    /// How far the presenting screen's bars, like a tab bar, reach above the window's bottom edge.
    /// See `Toast.bottomBarsHeight(windowHeight:windowBottomInset:screenBottom:screenBottomInset:)`.
    var screenBarsHeight: CGFloat = 0
    var bars: [Bar] = []

    /// How far the bars the toast clears reach above the window's bottom edge: the highest bar that shows
    /// and no presented screen covers, or the presenting screen's bars if they reach higher.
    var barsHeight: CGFloat {
        let heights = bars.filter(shows).map { windowSize.height - $0.frame.minY }
        return max(screenBarsHeight, heights.max() ?? 0)
    }

    /// The toast's distance from the window's bottom edge: `toastOffset`, raised to sit `spacing` above the bars.
    func bottomOffset(toastOffset: CGFloat, spacing: CGFloat) -> CGFloat {
        let height = barsHeight
        guard height > 0 else {
            return toastOffset
        }
        return max(toastOffset, height + spacing)
    }

    // MARK: Private

    /// How far a sheet can sit from the window's sides, like iOS 26's floating sheets, and still cover
    /// the part of a bar under the toast.
    private static let sheetSideMargin: CGFloat = 16

    private var windowBounds: CGRect {
        CGRect(origin: .zero, size: windowSize)
    }

    private func shows(_ bar: Bar) -> Bool {
        guard bar.isVisible, !bar.frame.isEmpty, bar.frame.intersects(windowBounds) else {
            return false
        }
        return !bar.screensAbove.contains { covers(bar: bar.frame, screen: $0) }
    }

    /// A sheet covers the bars under it: it reaches below the window's safe area and spans the bar.
    /// A popover, even a tall one, stays inside the safe area, so the bars under it still show.
    private func covers(bar: CGRect, screen: CGRect) -> Bool {
        let safeAreaBottom = windowSize.height - max(windowBottomInset, 1)
        let overlap = screen.intersection(bar)
        guard screen.maxY > safeAreaBottom, !overlap.isNull else {
            return false
        }
        return overlap.width >= bar.width - 2 * Self.sheetSideMargin
    }
}
