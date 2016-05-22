//
//  SQLiteQariTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SQLiteQariTimingRetriever: QariTimingRetriever {

    let persistence: QariAyahTimingPersistenceStorage

    func retrieveTimingForQari(qari: Qari, startAyah: AyahNumber, onCompletion: [AyahNumber: AyahTiming] -> Void) {
        guard case .Gapless(let databaseName) = qari.audioType else {
            fatalError("Gapped qaris are not supported.")
        }
        Queue.background.async {
            let fileURL = qari.localFolder().URLByAppendingPathComponent(databaseName).URLByAppendingPathExtension(Files.DatabaseLocalFileExtension)
            let timings = self.persistence.getTimingForSura(startAyah: startAyah, databaseFileURL: fileURL)
            Queue.main.async {
                onCompletion(timings)
            }
        }
    }

    func retrieveTimingForQari(qari: Qari, suras: [Int], onCompletion: [Int : [AyahTiming]] -> Void) {
        guard case .Gapless(let databaseName) = qari.audioType else {
            fatalError("Gapped qaris are not supported.")
        }
        Queue.background.async {
            let fileURL = qari.localFolder().URLByAppendingPathComponent(databaseName).URLByAppendingPathExtension(Files.DatabaseLocalFileExtension)

            var result: [Int: [AyahTiming]] = [:]
            for sura in suras {
                let timings = self.persistence.getOrderedTimingForSura(startAyah: AyahNumber(sura: sura, ayah: 1), databaseFileURL: fileURL)
                result[sura] = timings
            }

            Queue.main.async {
                onCompletion(result)
            }
        }
    }
}
