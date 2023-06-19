//
//  AdvancedAudioOptions.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/8/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QueuePlayer
import QuranAudio
import QuranKit

public struct AdvancedAudioOptions {
    // MARK: Lifecycle

    public init(reciter: Reciter, start: AyahNumber, end: AyahNumber, verseRuns: Runs, listRuns: Runs) {
        self.reciter = reciter
        self.start = start
        self.end = end
        self.verseRuns = verseRuns
        self.listRuns = listRuns
    }

    // MARK: Internal

    var reciter: Reciter
    var start: AyahNumber
    var end: AyahNumber
    var verseRuns: Runs
    var listRuns: Runs
}
