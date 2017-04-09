//
//  SQLiteQariTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
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
