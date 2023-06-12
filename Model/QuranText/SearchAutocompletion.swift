//
//  SearchAutocompletion.swift
//
//
//  Created by Afifi, Mohamed on 10/29/21.
//

import Foundation

public struct SearchAutocompletion: Hashable {
    public let text: String
    public let highlightedRange: NSRange?

    public init(text: String, term: String) {
        self.text = text
        highlightedRange = (text as NSString).range(of: term)
    }
}
