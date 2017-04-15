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

    fileprivate func processAyahInfo(_ info: [AyahNumber: [AyahInfo]]) -> [AyahNumber: [AyahInfo]] {
        var result = [AyahNumber: [AyahInfo]]()
        for (ayah, pieces) in info where !pieces.isEmpty {
            var ayahResult: [AyahInfo] = []
            ayahResult += [pieces[0]]
            var lastAyah = ayahResult[0]
            for i in 1..<pieces.count {
                if pieces[i].line != lastAyah.line {
                    lastAyah = pieces[i]
                    ayahResult += [ pieces[i] ]
                } else {
                    ayahResult += [ ayahResult.removeLast().engulf(pieces[i]) ]
                }
            }
            result[ayah] = ayahResult
        }
        return result
    }
}
