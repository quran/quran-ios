//
//  AudioEndLastAyahFinder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import QuranAudio
import QuranKit

/// Finds where playback ends for an `AudioEnd`: the end of its boundary, but
/// never before the end of the start page, so playback always covers the page
/// it starts on.
public struct AudioEndLastAyahFinder: LastAyahFinder {
    // MARK: Lifecycle

    public init(audioEnd: AudioEnd) {
        self.audioEnd = audioEnd
    }

    // MARK: Public

    public let audioEnd: AudioEnd

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        let pageLastVerse = PageBasedLastAyahFinder().findLastAyah(startAyah: startAyah)
        let lastVerse = audioEnd.boundaryLastAyahFinder.findLastAyah(startAyah: startAyah)
        return max(lastVerse, pageLastVerse)
    }
}

extension AudioEnd {
    /// Finds the end of this boundary alone, without the start page floor.
    public var boundaryLastAyahFinder: any LastAyahFinder {
        switch self {
        case .juz: return JuzBasedLastAyahFinder()
        case .sura: return SuraBasedLastAyahFinder()
        case .page: return PageBasedLastAyahFinder()
        case .quran: return QuranBasedLastAyahFinder()
        }
    }
}
