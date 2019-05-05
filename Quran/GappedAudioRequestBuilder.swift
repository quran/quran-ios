//
//  GappedAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MediaPlayer
import PromiseKit
import QueuePlayer

struct GappedAudioRequest: QuranAudioRequest {

    let request: AudioRequest
    let ayahs: [AyahNumber]
    let qari: Qari

    func getRequest() -> AudioRequest {
        return request
    }

    func getAyahNumberFrom(fileIndex: Int, frameIndex: Int) -> AyahNumber {
        return ayahs[fileIndex]
    }

    func getPlayerInfo(for fileIndex: Int) -> PlayerItemInfo {
        let ayah = ayahs[fileIndex]
        return PlayerItemInfo(title: ayah.localizedName,
                              artist: qari.name,
                              image: UIImage(named: qari.imageName))
    }
}

final class GappedAudioRequestBuilder: QuranAudioRequestBuilder {
    func buildRequest(with qari: Qari,
                      verseRange: VerseRange,
                      frameRuns: Runs,
                      requestRuns: Runs) -> Promise<QuranAudioRequest> {
        let (urls, ayahs) = urlsToPlay(qari: qari, range: verseRange)
        let files = urls.map { AudioFile(url: $0, frames: [AudioFrame(startTime: 0)]) }
        let request = AudioRequest(files: files, endTime: nil, frameRuns: frameRuns, requestRuns: requestRuns)
        let quranRequest = GappedAudioRequest(request: request, ayahs: ayahs, qari: qari)
        return Promise.value(quranRequest)
    }

    private func urlsToPlay(qari: Qari, range: VerseRange) -> (urls: [URL], ayahs: [AyahNumber]) {

        guard case AudioType.gapped = qari.audioType else {
            fatalError("Unsupported qari type gapless. Only gapless qaris can be downloaded here.")
        }

        var urls: [URL] = []
        var ayahs: [AyahNumber] = []

        for sura in range.lowerBound.sura...range.upperBound.sura {

            let startAyahNumber = sura == range.lowerBound.sura ? range.lowerBound.ayah : 1
            let endAyahNumber   = sura == range.upperBound.sura ? range.upperBound.ayah : Quran.numberOfAyahsForSura(sura)

            // add besm Allah for all except Al-Fatihah and At-Tawbah
            if startAyahNumber == 1 && (sura != 1 && sura != 9) {
                urls.append(createRequestInfo(qari: qari, sura: 1, ayah: 1))
                ayahs.append(AyahNumber(sura: sura, ayah: 1))
            }

            for ayah in startAyahNumber...endAyahNumber {
                urls.append(createRequestInfo(qari: qari, sura: sura, ayah: ayah))
                ayahs.append(AyahNumber(sura: sura, ayah: ayah))
            }
        }
        return (urls, ayahs)
    }

    fileprivate func createRequestInfo(qari: Qari, sura: Int, ayah: Int) -> URL {
        let fileName = sura.as3DigitString() + ayah.as3DigitString()
        return qari.localFolder().appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
    }
}
