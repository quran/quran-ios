//
//  ReciterTimingRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//

import AudioTimingPersistence
import Foundation
import QuranAudio
import QuranKit
import VLogging

public struct ReciterTimingRetriever {
    let persistenceFactory: (URL) -> AyahTimingPersistence = GRDBAyahTimingPersistence.init

    public init() {
    }

    public func timing(
        for reciter: Reciter,
        from start: AyahNumber,
        to end: AyahNumber
    ) async throws -> RangeTiming {
        let suras = start.sura.array(to: end.sura)
        let timings = try await retrieveTiming(for: reciter, suras: suras)

        // determine end time
        let endTime = getEndTime(timings: timings, from: start, to: end)

        // filter out uneeded timings
        let filteredTimings = filteredTimings(timings: timings, from: start, to: end)

        return RangeTiming(timings: filteredTimings, endTime: endTime)
    }

    private func retrieveTiming(for reciter: Reciter, suras: [Sura]) async throws -> [Sura: SuraTiming] {
        guard let fileURL = reciter.localDatabaseURL else {
            fatalError("Gapped reciters are not supported.")
        }
        let persistence = persistenceFactory(fileURL)

        var result: [Sura: SuraTiming] = [:]
        for sura in suras {
            let timings = try await persistence.getOrderedTimingForSura(startAyah: sura.firstVerse)
            result[sura] = timings
        }
        return result
    }

    private func getEndTime(timings: [Sura: SuraTiming], from start: AyahNumber, to end: AyahNumber) -> Timing? {
        let lastSuraTimings = timings[end.sura]!
        // end is the last verse in the sura
        if lastSuraTimings.verses.last?.ayah == end {
            return lastSuraTimings.endTime
        }
        if let endIndex = lastSuraTimings.verses.firstIndex(where: { $0.ayah == end }) {
            return lastSuraTimings.verses[endIndex + 1].time
        }
        logger.error("lastSuraTimings doesn't have the end verse")
        return nil
    }

    private func filteredTimings(
        timings: [Sura: SuraTiming],
        from start: AyahNumber,
        to end: AyahNumber
    ) -> [Sura: SuraTiming] {
        // filter out uneeded timings
        var mutableTimings: [Sura: SuraTiming] = [:]
        let ayahSet = Set(start.array(to: end))
        for (sura, suraTimings) in timings {
            var endTime: Timing?
            if let suraEndTime = suraTimings.endTime {
                if ayahSet.contains(suraTimings.verses.last!.ayah) {
                    endTime = suraEndTime
                }
            }
            mutableTimings[sura] = SuraTiming(verses: suraTimings.verses.filter { ayahSet.contains($0.ayah) }, endTime: endTime)
        }
        return mutableTimings
    }
}
