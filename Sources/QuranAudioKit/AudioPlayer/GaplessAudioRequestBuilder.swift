//
//  GaplessAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit
import QueuePlayer
import QuranKit
import QuranTextKit

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
                      requestRuns: Runs) -> Promise<QuranAudioRequest>
    {
        let urls = urlsToPlay(reciter: reciter, from: start, to: end)
        return timingRetriever.retrieveTiming(for: reciter, suras: urls.map(\.sura))
            .map(on: .global()) { timings -> QuranAudioRequest in

                // determine end time
                let endTime = self.getEndTime(timings: timings, from: start, to: end)

                // filter out uneeded timings
                let filteredTimings = self.filteredTimings(timings: timings, from: start, to: end)

                var files: [AudioFile] = []
                var ayahs: [[AyahNumber]] = []

                for (url, sura) in urls {
                    let suraTimings = filteredTimings[sura]!

                    var frames: [AudioFrame] = []
                    var fileAyahs: [AyahNumber] = []

                    for (offset, timing) in suraTimings.timings.enumerated() {
                        // start from 0 (beginning) if first ayah of the sura
                        let endTime = offset == suraTimings.timings.count - 1 ? suraTimings.endTime : nil
                        let frame = AudioFrame(startTime: offset == 0 && timing.ayah.ayah == 1 ? 0 : timing.seconds, endTime: endTime)
                        frames.append(frame)
                        fileAyahs.append(timing.ayah)
                    }
                    files.append(AudioFile(url: url, frames: frames))
                    ayahs.append(fileAyahs)
                }
                let request = AudioRequest(files: files, endTime: endTime, frameRuns: frameRuns, requestRuns: requestRuns)
                let quranRequest = GaplessAudioRequest(request: request, ayahs: ayahs, reciter: reciter)
                return quranRequest
            }
    }

    private func filteredTimings(timings: [Sura: [AyahTiming]],
                                 from start: AyahNumber,
                                 to end: AyahNumber) -> [Sura: (timings: [AyahTiming], endTime: TimeInterval?)]
    {
        // filter out uneeded timings
        var mutableTimings: [Sura: ([AyahTiming], endTime: TimeInterval?)] = [:]
        let ayahSet = Set(start.array(to: end))
        for (sura, suraTimings) in timings {
            var endTime: TimeInterval?
            if let clippedVerseTiming = suraTimings.last,
               clippedVerseTiming.ayah.ayah == 999 && suraTimings.count > 1
            {
                let lastVerseTiming = suraTimings[suraTimings.count - 2]
                if ayahSet.contains(lastVerseTiming.ayah) {
                    endTime = clippedVerseTiming.seconds
                }
            }
            mutableTimings[sura] = (suraTimings.filter { ayahSet.contains($0.ayah) }, endTime)
        }
        return mutableTimings
    }

    private func getEndTime(timings: [Sura: [AyahTiming]], from start: AyahNumber, to end: AyahNumber) -> TimeInterval? {
        var endTime: TimeInterval?
        let lastSuraTimings = timings[end.sura]!
        if let lastAyahIndex = lastSuraTimings.firstIndex(where: { $0.ayah == end }) {
            if lastAyahIndex + 1 < lastSuraTimings.count {
                let endTiming = lastSuraTimings[lastAyahIndex + 1]
                endTime = endTiming.seconds
            }
        }
        return endTime
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
