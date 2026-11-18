//
//  TwoPagesUtils.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import UIKit

public enum TwoPagesUtils {
    // MARK: Public

    /// Whether a window this wide has room for two Quran pages side by side.
    ///
    /// Pass the window's width, not the screen's: on iPhone Duo the screens differ from the window,
    /// and folding or unfolding resizes the window live.
    public static func hasEnoughHorizontalSpace(windowWidth: CGFloat) -> Bool {
        windowWidth > minimumWindowWidth
    }

    /// Whether the reader shows two pages: the preference is on and the window is wide enough.
    ///
    /// Only the window's width decides, not its size classes: iPad, an unfolded iPhone Duo, and large
    /// iPhones in landscape are wide enough, while narrow Split View, a folded iPhone Duo, and smaller iPhones aren't.
    public static func isEnabled(preference: Bool, windowWidth: CGFloat) -> Bool {
        preference && hasEnoughHorizontalSpace(windowWidth: windowWidth)
    }

    // MARK: Internal

    static let minimumWindowWidth: CGFloat = 900
}
