//
//  CollectionType+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/23/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

extension Collection where Index: Strideable {

    // Implementation from: http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array
    func binarySearch(_ predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = self.index(low, offsetBy: self.distance(from: low, to: high) / 2)
            if predicate(self[mid]) {
                low = self.index(mid, offsetBy: 1)
            } else {
                high = mid
            }
        }
        return low
    }
}


extension Collection where Index: Strideable, Iterator.Element: Comparable {
    func binarySearch(_ value: Iterator.Element) -> Index {
        return binarySearch { $0 < value }
    }
}
