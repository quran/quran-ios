//
//  DefaultAyahInfoPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
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

import PromiseKit

struct DefaultAyahInfoRetriever: AyahInfoRetriever {

    let persistence: AyahInfoPersistence

    func retrieveAyahs(in page: Int) -> Promise<[AyahNumber: [AyahInfo]]> {

        return DispatchQueue.default
            .promise2 { try self.persistence.getAyahInfoForPage(page) }
            .then { self.processAyahInfo($0) }
    }

    private func processAyahInfo(_ info: [AyahNumber: [AyahInfo]]) -> [AyahNumber: [AyahInfo]] {
        var groupedLines = info.flatMap { $0.value }.group { $0.line }
        let groupedLinesKeys = groupedLines.keys.sorted()
        for i in 0..<groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            let value = groupedLines[key]!
            groupedLines[key] = value.sorted { (info1, info2)  in
                guard info1.ayah.sura == info2.ayah.sura else {
                    return info1.ayah.sura < info2.ayah.sura
                }
                guard info1.ayah.ayah == info2.ayah.ayah else {
                    return info1.ayah.ayah < info2.ayah.ayah
                }
                return info1.position < info2.position
            }
        }

        // align vertically each line
        for i in 0..<groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            let list = groupedLines[key]!
            groupedLines[key] = AyahInfo.alignedVertically(list)
        }

        // union each line with its neighbors
        for i in 0..<groupedLinesKeys.count - 1 {
            let keyTop = groupedLinesKeys[i]
            let keyBottom = groupedLinesKeys[i + 1]
            var listTop = groupedLines[keyTop]!
            var listBottom = groupedLines[keyBottom]!
            AyahInfo.unionVertically(top: &listTop, bottom: &listBottom)
            groupedLines[keyTop] = listTop
            groupedLines[keyBottom] = listBottom
        }

        // union each position with its neighbors
        for i in 0..<groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            var list = groupedLines[key]!

            for j in 0..<list.count - 1 {
                var first = list[j]
                var second = list[j + 1]
                first.unionHorizontally(left: &second)
                list[j] = first
                list[j + 1] = second
            }
            groupedLines[key] = list
        }

        // align the edges
        var firstEdge = groupedLines.map { $0.value[0] }
        var lastEdge = groupedLines.map { $0.value[$0.value.count - 1] }
        AyahInfo.unionLeftEdge(&lastEdge)
        AyahInfo.unionRightEdge(&firstEdge)
        for i in 0..<groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            var list = groupedLines[key]!
            list[0] = firstEdge[i]
            list[list.count - 1] = lastEdge[i]
            groupedLines[key] = list
        }

        return groupedLines.flatMap { $0.value }.group { $0.ayah }
    }
}
