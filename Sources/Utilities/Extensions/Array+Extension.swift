//
//  Array+Extension.swift
//
//
//  Created by Mohamed Afifi on 2023-04-29.
//

import Foundation

extension Array where Element: Hashable {
    public func removingNeighboringDuplicates() -> [Element] {
        var uniqueList: [Element] = []
        for value in self {
            if value != uniqueList.last {
                uniqueList.append(value)
            }
        }
        return uniqueList
    }
}

extension Array {
    public func sortedAs<T: Hashable>(_ other: [T], by keyPath: KeyPath<Element, T>) -> [Element] {
        let indices = [T: Int](
            uniqueKeysWithValues: other.enumerated().map { ($0.element, $0.offset) })
        return sorted { (lhs: Element, rhs: Element) in
            indices[lhs[keyPath: keyPath]]! < indices[rhs[keyPath: keyPath]]!
        }
    }
}
