//
//  NoorImage.swift
//
//
//  Created by Mohamed Afifi on 2023-06-21.
//

import SwiftUI
import UIKit

public enum NoorImage: String {
    case ayahEnd = "ayah-end-marker"
    case pointer = "pointer-25"
    case suraHeader = "sura_header"

    // MARK: Public

    public var image: Image { Image(rawValue, bundle: .module) }
    public var uiImage: UIImage { UIImage(named: rawValue, in: .module, with: nil)! }
}
