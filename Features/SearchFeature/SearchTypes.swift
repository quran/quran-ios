//
//  SearchTypes.swift
//
//
//  Created by Mohamed Afifi on 2023-12-16.
//

import Foundation
import QuranText

enum SearchUIState {
    case entry
    case search(_ term: String)
}

enum SearchState {
    case searching
    case searchResult(_ results: [SearchResults])
}

enum KeyboardState {
    case open
    case closed
}
