//
//  QuranAudioRequestBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QueuePlayer
import QuranKit

protocol QuranAudioRequest {
    func getRequest() -> AudioRequest
    func getAyahNumberFrom(fileIndex: Int, frameIndex: Int) -> AyahNumber
    func getPlayerInfo(for fileIndex: Int) -> PlayerItemInfo
}

protocol QuranAudioRequestBuilder {
    func buildRequest(with reciter: Reciter,
                      from start: AyahNumber,
                      to end: AyahNumber,
                      frameRuns: Runs,
                      requestRuns: Runs) async throws -> QuranAudioRequest
}
