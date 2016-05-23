//
//  CollectionType+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/23/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

extension CollectionType where Index: RandomAccessIndexType {

    // Implementation from: http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array
    func binarySearch(predicate: Generator.Element -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = low.advancedBy(low.distanceTo(high) / 2)
            if predicate(self[mid]) {
                low = mid.advancedBy(1)
            } else {
                high = mid
            }
        }
        return low
    }
}


extension CollectionType where Index: RandomAccessIndexType, Generator.Element: Comparable {
    func binarySearch(value: Generator.Element) -> Index {
        return binarySearch { $0 < value }
    }
}
