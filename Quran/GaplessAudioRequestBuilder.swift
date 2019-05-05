//
//  GaplessAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MediaPlayer
import PromiseKit
import QueuePlayer

struct GaplessAudioRequest: QuranAudioRequest {

    let request: AudioRequest
    let ayahs: [[AyahNumber]]
    let qari: Qari

    func getRequest() -> AudioRequest {
        return request
    }

    func getAyahNumberFrom(fileIndex: Int, frameIndex: Int) -> AyahNumber {
        return ayahs[fileIndex][frameIndex]
    }

    func getPlayerInfo(for fileIndex: Int) -> PlayerItemInfo {
        return PlayerItemInfo(title: Quran.nameForSura(ayahs[fileIndex][0].sura),
                              artist: qari.name,
                              image: UIImage(named: qari.imageName))
    }
}

final class GaplessAudioRequestBuilder: QuranAudioRequestBuilder {

    private let timingRetriever: QariTimingRetriever

    init(timingRetriever: QariTimingRetriever) {
        self.timingRetriever = timingRetriever
    }

    func buildRequest(with qari: Qari,
                      verseRange: VerseRange,
                      frameRuns: Runs,
                      requestRuns: Runs) -> Promise<QuranAudioRequest> {
        let urls = urlsToPlay(qari: qari, range: verseRange)
        return timingRetriever.retrieveTiming(for: qari, suras: urls.map { $0.sura })
            .map(on: .global()) { timings -> QuranAudioRequest in

                // determine end time
                let endTime = self.getEndTime(timings: timings, range: verseRange)

                // filter out uneeded timings
                let filteredTimings = self.filteredTimings(timings: timings, range: verseRange)

                var files: [AudioFile] = []
                var ayahs: [[AyahNumber]] = []

                for (url, sura) in urls {
                    let suraTimings = unwrap(filteredTimings[sura])

                    var frames: [AudioFrame] = []
                    var fileAyahs: [AyahNumber] = []

                    for (offset, timing) in suraTimings.enumerated() {
                        // start from 0 (beginning) if first ayah of the sura
                        let frame = AudioFrame(startTime: offset == 0 && timing.ayah.ayah == 1 ? 0 : timing.seconds)
                        frames.append(frame)
                        fileAyahs.append(timing.ayah)
                    }
                    files.append(AudioFile(url: url, frames: frames))
                    ayahs.append(fileAyahs)
                }
                let request = AudioRequest(files: files, endTime: endTime, frameRuns: frameRuns, requestRuns: requestRuns)
                let quranRequest = GaplessAudioRequest(request: request, ayahs: ayahs, qari: qari)
                return quranRequest
            }
    }

    private func filteredTimings(timings: [Int: [AyahTiming]], range: VerseRange) -> [Int: [AyahTiming]] {
        // filter out uneeded timings
        var mutableTimings: [Int: [AyahTiming]] = [:]
        let ayahSet = Set(range.getAyahs())
        for (sura, suraTimings) in timings {
            mutableTimings[sura] = suraTimings.filter { ayahSet.contains($0.ayah) }
        }
        return mutableTimings
    }

    private func getEndTime(timings: [Int: [AyahTiming]], range: VerseRange) -> TimeInterval? {
        var endTime: TimeInterval?
        let lastSuraTimings = unwrap(timings[range.upperBound.sura])
        if let lastAyahIndex = lastSuraTimings.index(where: { $0.ayah == range.upperBound }) {
            if lastAyahIndex + 1 < lastSuraTimings.count {
                let endTiming = lastSuraTimings[lastAyahIndex + 1]
                // DB has 999 represents the last ayah end time
                if endTiming.ayah.ayah != 999 {
                    endTime = endTiming.seconds
                }
            }
        }
        return endTime
    }

    private func urlsToPlay(qari: Qari, range: VerseRange) -> [(url: URL, sura: Int)] {

        guard case AudioType.gapless = qari.audioType else {
            fatalError("Unsupported qari type gapped. Only gapless qaris can be played here.")
        }

        // loop over the files
        var files: [(URL, Int)] = []
        for sura in range.lowerBound.sura...range.upperBound.sura {
            let fileName = sura.as3DigitString()
            let localURL = qari.localFolder().appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            files.append((localURL, sura))
        }
        return files
    }
}
