//
//  TwoPagesUtils.swift
//
//
//  Created by Zubair Khan on 2022-11-12.
//

import UIKit

public struct TwoPagesUtils {
    public static func hasEnoughHorizontalSpace() -> Bool {
        UIScreen.main.bounds.width > 900
    }

    public static var settingDefaultValue: Bool {
        // Enable by default, if not an iPhone
        UIDevice.current.userInterfaceIdiom != .phone
    }
}
