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

    public func sortedAs(_ other: [Element]) -> [Element] {
        sortedAs(other: other) { $0 }
    }
}

extension Array {
    public func sortedAs<T: Hashable>(other: [T], transform: (Element) -> T) -> [Element] {
        let indices = [T: Int](
            uniqueKeysWithValues: other.enumerated().map { ($0.element, $0.offset) })
        return sorted { (lhs: Element, rhs: Element) in
            indices[transform(lhs)]! < indices[transform(rhs)]!
        }
    }
}
