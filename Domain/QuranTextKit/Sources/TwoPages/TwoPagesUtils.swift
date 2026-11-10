//
//  TwoPagesUtils.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import UIKit

public enum TwoPagesUtils {
    // MARK: Public

    /// The value reported for people who never chose, when no window is available to decide.
    public static var settingDefaultValue: Bool {
        UIDevice.current.userInterfaceIdiom != .phone
    }

    /// Whether a window this wide has room for two Quran pages side by side.
    ///
    /// Pass the window's width, not the screen's: on iPhone Duo the screens differ from the window,
    /// and folding or unfolding resizes the window live.
    public static func hasEnoughHorizontalSpace(windowWidth: CGFloat) -> Bool {
        windowWidth > minimumWindowWidth
    }

    /// Whether two pages are on, given the stored preference and the window's size classes.
    ///
    /// People who never chose get two pages in windows that are regular in both dimensions,
    /// like iPad or an unfolded iPhone Duo, and a single page elsewhere, like an iPhone in landscape.
    public static func isEnabled(preference: Bool?, isRegularWidthAndHeight: Bool) -> Bool {
        preference ?? isRegularWidthAndHeight
    }

    // MARK: Internal

    static let minimumWindowWidth: CGFloat = 900
}
