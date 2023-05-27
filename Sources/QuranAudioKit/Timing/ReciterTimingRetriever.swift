//
//  ReciterTimingRetriever.swift
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
import QuranKit

struct ReciterTimingRetriever {
    let persistenceFactory: AyahTimingPersistenceFactory

    func retrieveTiming(for reciter: Reciter, suras: [Sura]) async throws -> [Sura: SuraTiming] {
        guard case .gapless(let databaseName) = reciter.audioType else {
            fatalError("Gapped reciters are not supported.")
        }
        let fileURL = reciter.localFolder().appendingPathComponent(databaseName).appendingPathExtension(Files.databaseLocalFileExtension)
        let persistence = persistenceFactory.persistenceForURL(fileURL)

        var result: [Sura: SuraTiming] = [:]
        for sura in suras {
            let timings = try await persistence.getOrderedTimingForSura(startAyah: sura.firstVerse)
            result[sura] = timings
        }
        return result
    }
}
