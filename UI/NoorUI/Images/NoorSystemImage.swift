//
//  NoorSystemImage.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI

public enum NoorSystemImage: String {
    case audio = "headphones"
    case downloads = "square.and.arrow.down"
    case download = "icloud.and.arrow.down"
    case translation = "globe"
    case share = "square.and.arrow.up"
    case star
    case mail = "envelope"
    case checkmark_checked = "checkmark.circle.fill"
    case checkmark_unchecked = "circle"

    // MARK: Public

    public var image: Image {
        Image(systemName: rawValue)
    }
}
