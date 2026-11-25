//
//  ReaderWindow.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import CoreGraphics
import MoreMenuFeature
import QuranTextKit

/// What the reader's window offers the More menu. iPhone Duo resizes the window when it folds or unfolds.
struct ReaderWindow: Equatable {
    let size: CGSize
    let isRegularWidthAndHeight: Bool
    let isPhone: Bool
}

/// The More menu controls that depend on the reader's window.
struct MoreMenuWindowOptions: Equatable {
    // MARK: Lifecycle

    /// - Parameter window: The reader's window, or `nil` while the reader isn't in one.
    init(window: ReaderWindow?) {
        let hasRoomForTwoPages = window.map { TwoPagesUtils.hasRoomForTwoPages(windowSize: $0.size) } ?? false
        let isRegularWidthAndHeight = window?.isRegularWidthAndHeight ?? false
        twoPages = hasRoomForTwoPages ? .conditional : .alwaysOff
        // An unfolded iPhone Duo resizes instead of rotating, so the rotate buttons would do nothing.
        // iPad rotates, so it keeps them.
        orientation = isRegularWidthAndHeight && window?.isPhone == true ? .alwaysOff : .conditional
    }

    // MARK: Internal

    let twoPages: ConfigState
    let orientation: ConfigState
}
