//
//  MultiPredicateComparer.swift
//
//
//  Created by Mohamed Afifi on 2023-07-09.
//

public struct MultiPredicateComparer<T> {
    public typealias Predicate = (T, T) -> Bool

    // MARK: Lifecycle

    public init(increasingOrderPredicates: [Predicate]) {
        self.increasingOrderPredicates = increasingOrderPredicates
    }

    // MARK: Public

    public func areInIncreasingOrder(lhs: T, rhs: T) -> Bool {
        for predicate in increasingOrderPredicates {
            if predicate(lhs, rhs) != predicate(rhs, lhs) {
                return predicate(lhs, rhs)
            }
        }
        return false
    }

    // MARK: Private

    private let increasingOrderPredicates: [Predicate]
}
