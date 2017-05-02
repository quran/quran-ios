//
//  CollectionType+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/23/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

extension Collection where Index: Strideable {

    // Implementation from: http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array
    public func binarySearch(_ predicate: (Iterator.Element) -> Bool) -> Index {
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
    public func binarySearch(_ value: Iterator.Element) -> Index {
        return binarySearch { $0 < value }
    }
}
