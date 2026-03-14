//
//  WordTimingScheduler.swift
//  Quran
//
//  Created for Quran.com iOS app.
//

import Foundation
import QuranKit
import WordAnnotationService

/// Schedules per-word highlight callbacks based on QuranCDN segment timing.
///
/// When an ayah starts playing, this scheduler fetches or reuses cached segment
/// data for the sura and fires `onWord` at the appropriate time offsets relative
/// to when `schedule` is called.
@MainActor
final class WordTimingScheduler {
    // MARK: Internal

    /// Called with each word as it starts, then nil when the verse is done.
    var onWord: ((Word?) -> Void)?

    func schedule(ayah: AyahNumber, reciter: Reciter, playerTimeOffset: Double) {
        cancel()
        currentAyah = ayah

        Task { [weak self] in
            guard let self else { return }
            await self.fetchAndSchedule(ayah: ayah, reciter: reciter, playerTimeOffset: playerTimeOffset)
        }
    }

    func cancel() {
        for timer in wordTimers { timer.invalidate() }
        wordTimers = []
        currentAyah = nil
        onWord?(nil)
    }

    // MARK: Private

    private let service = WordTimingService()
    /// Cache: sura number → verse key → segments
    private var segmentCache: [Int: [String: [[Int]]]] = [:]
    private var wordTimers: [Timer] = []
    private var currentAyah: AyahNumber?

    private func fetchAndSchedule(ayah: AyahNumber, reciter: Reciter, playerTimeOffset: Double) async {
        let chapter = ayah.sura.suraNumber
        if segmentCache[chapter] == nil {
            segmentCache[chapter] = (try? await service.segments(for: reciter, chapter: chapter)) ?? [:]
        }

        guard let segments = segmentCache[chapter]?["\(chapter):\(ayah.ayah)"],
              currentAyah == ayah
        else { return }

        let now = Date()
        for segment in segments {
            guard segment.count >= 3 else { continue }
            let wordNumber = segment[0]
            let startMs = segment[1]

            // Time from now until this word starts, accounting for where in the file we are.
            let delay = (Double(startMs) / 1000.0) - playerTimeOffset

            if delay < 0 { continue } // word already passed

            let word = Word(verse: ayah, wordNumber: wordNumber)
            let fireDate = now.addingTimeInterval(delay)
            let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.currentAyah == ayah else { return }
                    self.onWord?(word)
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            wordTimers.append(timer)
        }
    }
}
