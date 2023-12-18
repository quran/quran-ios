//
//  SearchTypes.swift
//
//
//  Created by Mohamed Afifi on 2023-12-16.
//

import Foundation

enum SearchUIState {
    case entry
    case autocomplete
    case loading
    case searchResults
}

enum SearchTerm {
    case autocomplete(_ term: String)
    case noAction(_ term: String)

    // MARK: Internal

    var term: String {
        switch self {
        case .autocomplete(let term), .noAction(let term): return term
        }
    }

    var isAutocomplete: Bool {
        switch self {
        case .autocomplete: return true
        case .noAction: return false
        }
    }
}
