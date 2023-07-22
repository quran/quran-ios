//
//  NoorImage.swift
//
//
//  Created by Mohamed Afifi on 2023-06-21.
//

import SwiftUI
import UIKit

public enum NoorImage: String {
    case ayahEnd = "ayah-end"
    case innerShadow = "inner-shadow"
    case pointer = "pointer-25"
    case rotateToLandscape = "rotate_to_landscape-25"
    case rotateToPortrait = "rotate_to_portrait-25"
    case settings = "settings-25"
    case settingsFilled = "settings_filled-25"
    case suraHeader = "sura_header"
    case suraDecorationLeft = "sura-decoration-left"
    case suraDecorationMiddle = "sura-decoration-middle"
    case suraDecorationRight = "sura-decoration-right"

    // MARK: Public

    public var image: Image { Image(rawValue, bundle: .module) }
    public var uiImage: UIImage { UIImage(named: rawValue, in: .module, with: nil)! }
}
