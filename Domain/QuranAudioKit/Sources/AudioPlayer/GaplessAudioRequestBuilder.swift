//
//  GaplessAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AudioTimingService
import QueuePlayer
import QuranAudio
import QuranKit
import QuranTextKit
import Utilities

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
        PlayerItemInfo(
            title: ayahs[fileIndex][0].sura.localizedName(),
            artist: reciter.localizedName,
            image: nil
        )
    }
}

struct GaplessAudioRequestBuilder: QuranAudioRequestBuilder {
    // MARK: Internal

    let timingRetriever = ReciterTimingRetriever()

    func buildRequest(
        with reciter: Reciter,
        from start: AyahNumber,
        to end: AyahNumber,
        frameRuns: Runs,
        requestRuns: Runs
    ) async throws -> QuranAudioRequest {
        let range = try await timingRetriever.timing(for: reciter, from: start, to: end)
        let surasPaths = urlsToPlay(reciter: reciter, suras: range.timings.keys)

        var files: [AudioFile] = []
        var ayahs: [[AyahNumber]] = []

        for (path, sura) in surasPaths {
            let suraTimings = range.timings[sura]!

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
            files.append(AudioFile(url: path.url, frames: frames))
            ayahs.append(fileAyahs)
        }
        let request = AudioRequest(files: files, endTime: range.endTime?.seconds, frameRuns: frameRuns, requestRuns: requestRuns)
        let quranRequest = GaplessAudioRequest(request: request, ayahs: ayahs, reciter: reciter)
        return quranRequest
    }

    // MARK: Private

    private func urlsToPlay(reciter: Reciter, suras: some Collection<Sura>) -> [(path: RelativeFilePath, sura: Sura)] {
        guard case AudioType.gapless = reciter.audioType else {
            fatalError("Unsupported reciter type gapped. Only gapless reciters can be played here.")
        }

        // loop over the files
        var files: [(RelativeFilePath, Sura)] = []
        for sura in suras.sorted() {
            let localURL = reciter.localURL(sura: sura)
            files.append((localURL, sura))
        }
        return files
    }
}
