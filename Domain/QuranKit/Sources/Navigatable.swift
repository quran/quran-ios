//
//  Navigatable.swift
//
//
//  Created by Mohamed Afifi on 2021-12-12.
//

import Foundation

public protocol Navigatable: Comparable, Hashable, CustomStringConvertible, Sendable {
    var next: Self? { get }
    var previous: Self? { get }
}

extension Navigatable {
    public func array(to end: Self) -> [Self] {
        precondition(end >= self, "End \(type(of: self)) is less than first one.")
        var values = [self]
        var pointer = self
        while let next = pointer.next, next <= end {
            pointer = next
            values.append(next)
        }
        return values
    }
}
