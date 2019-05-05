//
//  QuranAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import PromiseKit
import QueuePlayer

protocol QuranAudioRequest {
    func getRequest() -> AudioRequest
    func getAyahNumberFrom(fileIndex: Int, frameIndex: Int) -> AyahNumber
    func getPlayerInfo(for fileIndex: Int) -> PlayerItemInfo
}

protocol QuranAudioRequestBuilder {
    func buildRequest(with qari: Qari,
                      verseRange: VerseRange,
                      frameRuns: Runs,
                      requestRuns: Runs) -> Promise<QuranAudioRequest>
}
