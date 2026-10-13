//
//  TextLengthLimitError.swift
//
//  Created by Mohamed Afifi on 2026-10-13.
//

/// The server measures the length after HTML-escaping, so `&`, `<` and `>` count as several characters.
public struct TextLengthLimitError: Error, Equatable, Sendable {
    // MARK: Lifecycle

    public init(field: Field, bound: Bound, limit: Int) {
        self.field = field
        self.bound = bound
        self.limit = limit
    }

    // MARK: Public

    public enum Field: Equatable, Sendable {
        case noteBody
        case collectionName
    }

    public enum Bound: Equatable, Sendable {
        case tooShort
        case tooLong
    }

    public let field: Field
    public let bound: Bound
    public let limit: Int
}
