//
//  SearchAutocompletion.swift
//
//
//  Created by Afifi, Mohamed on 10/29/21.
//

import Foundation

public struct SearchAutocompletion: Hashable {
    // MARK: Lifecycle

    public init(text: String, term: String) {
        self.text = text
        highlightedRange = (text as NSString).range(of: term)
    }

    // MARK: Public

    public let text: String
    public let highlightedRange: NSRange?
}
