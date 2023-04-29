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
