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
    case checkmark
    case bookmark = "bookmark.fill"
    case note = "text.badge.star"
    case lastPage = "clock"
    case search = "magnifyingglass"
    case mushafs = "books.vertical.fill"
    case debug = "ant"
    case play = "play.fill"
    case stop = "stop.fill"
    case pause = "pause.fill"
    case more = "ellipsis.circle"
    case backward = "backward.fill"
    case forward = "forward.fill"
    case cancel = "xmark"

    // MARK: Public

    public var image: Image {
        Image(systemName: rawValue)
    }
}
