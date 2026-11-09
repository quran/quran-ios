//
//  ToastPlacement.swift
//
//
//  Created by Mohamed Afifi on 2026-11-08.
//

import UIKit

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
    /// The window's safe-area insets, like the home indicator's at the bottom or the sensor housing's on the
    /// side in landscape.
    var windowSafeAreaInsets: UIEdgeInsets
    /// How far the presenting screen's bars, like a tab bar, reach above the window's bottom edge.
    /// See `screenBarsHeight(windowHeight:windowBottomInset:screenBottom:screenBottomInset:)`.
    var screenBarsHeight: CGFloat = 0
    var bars: [Bar] = []

    /// How far the bars the toast clears reach above the window's bottom edge: the highest bar that shows
    /// and no presented screen covers, or the presenting screen's bars if they reach higher.
    var barsHeight: CGFloat {
        let heights = bars.filter(shows).map { windowSize.height - $0.frame.minY }
        return max(screenBarsHeight, heights.max() ?? 0)
    }

    /// How far a screen's bottom bars, like a tab bar, reach above the window's bottom edge.
    /// Only a screen that reaches the window's bottom edge has bars, and only when its bottom inset
    /// is taller than the home indicator's; a popover, even one with a down arrow, has none.
    /// A screen that stops above an opaque tab bar isn't detected. Bars a screen can't report through its
    /// safe area, like the reader's audio bar, keep toasts above them with `keepsToastsAbove`.
    static func screenBarsHeight(
        windowHeight: CGFloat,
        windowBottomInset: CGFloat,
        screenBottom: CGFloat,
        screenBottomInset: CGFloat
    ) -> CGFloat {
        guard screenBottom >= windowHeight - 0.5, screenBottomInset > windowBottomInset else {
            return 0
        }
        return screenBottomInset
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

    /// The toast's side padding, the system's default, by which it stays inside the window's safe area.
    private static let toastSideMargin: CGFloat = 16

    private var windowBounds: CGRect {
        CGRect(origin: .zero, size: windowSize)
    }

    /// The window's horizontal span the toast can show in.
    private var toastSpan: ClosedRange<CGFloat> {
        let minX = windowSafeAreaInsets.left + Self.toastSideMargin
        let maxX = windowSize.width - windowSafeAreaInsets.right - Self.toastSideMargin
        return minX ... max(minX, maxX)
    }

    private func shows(_ bar: Bar) -> Bool {
        guard bar.isVisible, !bar.frame.isEmpty, bar.frame.intersects(windowBounds) else {
            return false
        }
        return !bar.screensAbove.contains { covers(bar: bar.frame, screen: $0) }
    }

    /// A sheet covers the bars under it: it reaches below the window's safe area and spans the part of the
    /// bar the toast could cover, the part inside the window's horizontal safe area. A popover, even a tall
    /// one, stays inside the safe area, so the bars under it still show.
    private func covers(bar: CGRect, screen: CGRect) -> Bool {
        let safeAreaBottom = windowSize.height - max(windowSafeAreaInsets.bottom, 1)
        guard screen.maxY > safeAreaBottom, screen.intersects(bar) else {
            return false
        }
        let barUnderToast = max(bar.minX, toastSpan.lowerBound) ... max(min(bar.maxX, toastSpan.upperBound), toastSpan.lowerBound)
        return screen.minX <= barUnderToast.lowerBound + 0.5 && screen.maxX >= barUnderToast.upperBound - 0.5
    }
}
