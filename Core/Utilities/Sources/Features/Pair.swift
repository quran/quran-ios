//
//  Pair.swift
//
//
//  Created by Mohamed Afifi on 2024-02-02.
//

public struct Pair<First, Second> {
    public var first: First
    public var second: Second

    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

extension Pair: Equatable where First: Equatable, Second: Equatable { }
extension Pair: Hashable where First: Hashable, Second: Hashable { }
