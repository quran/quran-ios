//
//  QuranText.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

/// Text that must be rendered using a Quran font.
public struct QuranText: Hashable, Sendable {
    // MARK: Lifecycle

    public init(_ text: String) {
        self.text = text
    }

    // MARK: Public

    public let text: String
}

extension QuranText: CustomStringConvertible {
    public var description: String { text }
}

extension QuranText: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
