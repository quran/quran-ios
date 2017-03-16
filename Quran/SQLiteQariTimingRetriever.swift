//
//  SQLiteQariTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SQLiteQariTimingRetriever: QariTimingRetriever {

    let persistenceCreator: AnyCreator<QariAyahTimingPersistence, URL>

    func retrieveTimingForQari(_ qari: Qari, startAyah: AyahNumber, onCompletion: @escaping (Result<[AyahNumber: AyahTiming]>) -> Void) {
        guard case .gapless(let databaseName) = qari.audioType else {
            fatalError("Gapped qaris are not supported.")
        }
        Queue.background.tryAsync({
            let fileURL = qari.localFolder().appendingPathComponent(databaseName).appendingPathExtension(Files.databaseLocalFileExtension)
            let persistence = self.persistenceCreator.create(parameters: fileURL)
            let timings = try persistence.getTimingForSura(startAyah: startAyah)
            return timings
        }, onMain: onCompletion)
    }

    func retrieveTimingForQari(_ qari: Qari, suras: [Int], onCompletion: @escaping (Result<[Int : [AyahTiming]]>) -> Void) {
        guard case .gapless(let databaseName) = qari.audioType else {
            fatalError("Gapped qaris are not supported.")
        }
        Queue.background.tryAsync({
            let fileURL = qari.localFolder().appendingPathComponent(databaseName).appendingPathExtension(Files.databaseLocalFileExtension)
            let persistence = self.persistenceCreator.create(parameters: fileURL)

            var result: [Int: [AyahTiming]] = [:]
            for sura in suras {
                let timings = try persistence.getOrderedTimingForSura(startAyah: AyahNumber(sura: sura, ayah: 1))
                result[sura] = timings
            }
            return result
        }, onMain: onCompletion)
    }
}
