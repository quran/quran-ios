//
//  SearchAutocompletion.swift
//
//
//  Created by Afifi, Mohamed on 10/29/21.
//

import Foundation

public struct SearchAutocompletion: Hashable {
    public let text: String
    public let highlightedRange: Range<String.Index>
}
