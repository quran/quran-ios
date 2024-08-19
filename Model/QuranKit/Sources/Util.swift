//
//  Util.swift
//
//
//  Created by Mohamed Afifi on 2022-01-08.
//

extension RandomAccessCollection {
    func binarySearchFirst(predicate: (Element) -> Bool) -> Element {
        let index = binarySearchIndex(predicate: predicate)
        let previousIndex = self.index(index, offsetBy: -1)
        return self[previousIndex]
    }

    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearchIndex(predicate: (Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}
