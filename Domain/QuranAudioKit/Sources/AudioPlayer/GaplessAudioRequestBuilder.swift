//
//  GaplessAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import QueuePlayer
import QuranKit
import QuranTextKit
import VLogging
import AyahTimingPersistence

struct GaplessAudioRequest: QuranAudioRequest {
    let request: AudioRequest
    let ayahs: [[AyahNumber]]
    let reciter: Reciter

    func getRequest() -> AudioRequest {
        request
    }

    func getAyahNumberFrom(fileIndex: Int, frameIndex: Int) -> AyahNumber {
        ayahs[fileIndex][frameIndex]
    }

    func getPlayerInfo(for fileIndex: Int) -> PlayerItemInfo {
        PlayerItemInfo(title: ayahs[fileIndex][0].sura.localizedName(),
                       artist: reciter.localizedName,
                       image: nil)
    }
}

final class GaplessAudioRequestBuilder: QuranAudioRequestBuilder {
    private let timingRetriever: ReciterTimingRetriever

    init(timingRetriever: ReciterTimingRetriever) {
        self.timingRetriever = timingRetriever
    }

    func buildRequest(with reciter: Reciter,
                      from start: AyahNumber,
                      to end: AyahNumber,
                      frameRuns: Runs,
                      requestRuns: Runs) async throws -> QuranAudioRequest
    {
        let urls = urlsToPlay(reciter: reciter, from: start, to: end)
        let timings = try await timingRetriever.retrieveTiming(for: reciter, suras: urls.map(\.sura))

        // determine end time
        let endTime = getEndTime(timings: timings, from: start, to: end)

        // filter out uneeded timings
        let filteredTimings = filteredTimings(timings: timings, from: start, to: end)

        var files: [AudioFile] = []
        var ayahs: [[AyahNumber]] = []

        for (url, sura) in urls {
            let suraTimings = filteredTimings[sura]!

            var frames: [AudioFrame] = []
            var fileAyahs: [AyahNumber] = []

            for (offset, verse) in suraTimings.verses.enumerated() {
                // start from 0 (beginning) if first ayah of the sura
                let endTime = offset == suraTimings.verses.count - 1 ? suraTimings.endTime : nil

                var startTimeSeconds = verse.time.seconds

                // Do not include the basmalah when the first verse is repeated
                if offset == 0 && verse.ayah.ayah == 1 && (requestRuns == .one || !ayahs.isEmpty) {
                    startTimeSeconds = 0
                }

                let frame = AudioFrame(startTime: startTimeSeconds, endTime: endTime?.seconds)
                frames.append(frame)
                fileAyahs.append(verse.ayah)
            }
            files.append(AudioFile(url: url, frames: frames))
            ayahs.append(fileAyahs)
        }
        let request = AudioRequest(files: files, endTime: endTime?.seconds, frameRuns: frameRuns, requestRuns: requestRuns)
        let quranRequest = GaplessAudioRequest(request: request, ayahs: ayahs, reciter: reciter)
        return quranRequest
    }

    private func filteredTimings(timings: [Sura: SuraTiming],
                                 from start: AyahNumber,
                                 to end: AyahNumber) -> [Sura: SuraTiming]
    {
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

    private func urlsToPlay(reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [(url: URL, sura: Sura)] {
        guard case AudioType.gapless = reciter.audioType else {
            fatalError("Unsupported reciter type gapped. Only gapless reciters can be played here.")
        }

        // loop over the files
        var files: [(URL, Sura)] = []
        for sura in start.sura.array(to: end.sura) {
            let fileName = sura.suraNumber.as3DigitString()
            let localURL = reciter.localFolder().appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            files.append((localURL, sura))
        }
        return files
    }
}
