//
//  TwoPagesUtils.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import UIKit

public enum TwoPagesUtils {
    // MARK: Public

    /// Whether a window this size has room for two Quran pages side by side: it's wider than 900pt
    /// and isn't portrait.
    ///
    /// Pass the window's size, not the screen's: on iPhone Duo the screens differ from the window,
    /// and folding or unfolding resizes the window live.
    public static func hasRoomForTwoPages(windowSize: CGSize) -> Bool {
        windowSize.width > minimumWindowWidth && windowSize.width >= windowSize.height
    }

    /// Whether the reader shows two pages: the preference is on and the window has room for them.
    ///
    /// Only the window's size decides, not its size classes: iPad, an unfolded iPhone Duo, and large iPhones
    /// in landscape have room, while portrait windows, narrow Split View, a folded iPhone Duo, and smaller
    /// iPhones don't.
    public static func isEnabled(preference: Bool, windowSize: CGSize) -> Bool {
        preference && hasRoomForTwoPages(windowSize: windowSize)
    }

    // MARK: Internal

    static let minimumWindowWidth: CGFloat = 900
}
