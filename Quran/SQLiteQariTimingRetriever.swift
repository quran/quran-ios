//
//  SQLiteQariTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

struct SQLiteQariTimingRetriever: QariTimingRetriever {

    let persistenceCreator: AnyCreator<QariAyahTimingPersistence, URL>

    func retrieveTiming(for qari: Qari, startAyah: AyahNumber) -> Promise<[AyahNumber: AyahTiming]> {
        guard case .gapless(let databaseName) = qari.audioType else {
            fatalError("Gapped qaris are not supported.")
        }

        return DispatchQueue.global() .promise {
                let fileURL = qari.localFolder().appendingPathComponent(databaseName).appendingPathExtension(Files.databaseLocalFileExtension)
                let persistence = self.persistenceCreator.create(fileURL)
                let timings = try persistence.getTimingForSura(startAyah: startAyah)
                return timings
        }
    }

    func retrieveTiming(for qari: Qari, suras: [Int]) -> Promise<[Int: [AyahTiming]]> {
        guard case .gapless(let databaseName) = qari.audioType else {
            fatalError("Gapped qaris are not supported.")
        }
        return DispatchQueue.global() .promise {
            let fileURL = qari.localFolder().appendingPathComponent(databaseName).appendingPathExtension(Files.databaseLocalFileExtension)
            let persistence = self.persistenceCreator.create(fileURL)

            var result: [Int: [AyahTiming]] = [:]
            for sura in suras {
                let timings = try persistence.getOrderedTimingForSura(startAyah: AyahNumber(sura: sura, ayah: 1))
                result[sura] = timings
            }
            return result
        }
    }
}
