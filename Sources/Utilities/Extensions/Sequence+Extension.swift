//
//  Sequence+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/19/17.
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

import Foundation

public extension Sequence {
    func flatGroup<U: Hashable>(by key: (Iterator.Element) -> U) -> [U: Iterator.Element] {
        var categories: [U: Iterator.Element] = [:]
        for element in self {
            let key = key(element)
            categories[key] = element
        }
        return categories
    }
}

extension Sequence where Iterator.Element: Hashable {
    public func orderedUnique() -> [Iterator.Element] {
        var buffer: [Iterator.Element] = []
        var added: Set<Iterator.Element> = []
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}
