//
//  Navigatable.swift
//
//
//  Created by Mohamed Afifi on 2021-12-12.
//

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

extension Sequence where Element: Navigatable {
    /// The values, sorted and without duplicates, grouped into runs of consecutive values.
    public func consecutiveRanges() -> [ClosedRange<Element>] {
        var ranges: [ClosedRange<Element>] = []
        for value in Set(self).sorted() {
            if let last = ranges.last, last.upperBound.next == value {
                ranges[ranges.count - 1] = last.lowerBound ... value
            } else {
                ranges.append(value ... value)
            }
        }
        return ranges
    }
}
