//
//  GappedAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import QueuePlayer
import QuranAudio
import QuranKit

struct GappedAudioRequest: QuranAudioRequest {
    let request: AudioRequest
    let ayahs: [AyahNumber]
    let reciter: Reciter

    func getRequest() -> AudioRequest {
        request
    }

    func getAyahNumberFrom(fileIndex: Int, frameIndex: Int) -> AyahNumber {
        ayahs[fileIndex]
    }

    func getPlayerInfo(for fileIndex: Int) -> PlayerItemInfo {
        let ayah = ayahs[fileIndex]
        return PlayerItemInfo(
            title: ayah.localizedName,
            artist: reciter.localizedName,
            image: nil
        )
    }
}

final class GappedAudioRequestBuilder: QuranAudioRequestBuilder {
    // MARK: Internal

    func buildRequest(
        with reciter: Reciter,
        from start: AyahNumber,
        to end: AyahNumber,
        frameRuns: Runs,
        requestRuns: Runs
    ) async throws -> QuranAudioRequest {
        let (urls, ayahs) = urlsToPlay(reciter: reciter, from: start, to: end, requestRuns: requestRuns)
        let files = urls.map {
            AudioFile(url: $0, frames: [AudioFrame(startTime: 0, endTime: nil)])
        }
        let request = AudioRequest(files: files, endTime: nil, frameRuns: frameRuns, requestRuns: requestRuns)
        let quranRequest = GappedAudioRequest(request: request, ayahs: ayahs, reciter: reciter)
        return quranRequest
    }

    // MARK: Private

    private func urlsToPlay(reciter: Reciter, from start: AyahNumber, to end: AyahNumber, requestRuns: Runs) -> (urls: [URL], ayahs: [AyahNumber]) {
        guard case AudioType.gapped = reciter.audioType else {
            fatalError("Unsupported reciter type gapless. Only gapless reciters can be downloaded here.")
        }

        var urls: [URL] = []
        var ayahs: [AyahNumber] = []
        let verses = start.array(to: end)
        let surasDictionary = Dictionary(grouping: verses, by: { $0.sura })

        for sura in surasDictionary.keys.sorted() {
            let verses = surasDictionary[sura] ?? []

            // add besm Allah for all except Al-Fatihah and At-Tawbah
            if (requestRuns == .one || !ayahs.isEmpty) && sura.startsWithBesmAllah && verses[0] == sura.firstVerse {
                urls.append(reciter.localURL(ayah: start.quran.firstVerse))
                ayahs.append(verses[0])
            }
            for verse in verses {
                urls.append(reciter.localURL(ayah: verse))
                ayahs.append(verse)
            }
        }
        return (urls, ayahs)
    }
}
