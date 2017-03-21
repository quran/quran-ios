//
//  DefaultAyahInfoPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import PromiseKit

struct DefaultAyahInfoRetriever: AyahInfoRetriever {

    let persistence: AyahInfoPersistence

    func retrieveAyahs(in page: Int) -> Promise<[AyahNumber: [AyahInfo]]> {

        return DispatchQueue.global()
            .promise { try self.persistence.getAyahInfoForPage(page) }
            .then(on: .global()) { self.processAyahInfo($0) }
    }

    fileprivate func processAyahInfo(_ info: [AyahNumber: [AyahInfo]]) -> [AyahNumber: [AyahInfo]] {
        var result = [AyahNumber: [AyahInfo]]()
        for (ayah, pieces) in info {
            guard pieces.count > 0 else { continue }
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
