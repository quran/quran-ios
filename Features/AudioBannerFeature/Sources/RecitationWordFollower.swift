//
//  RecitationWordFollower.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

import AudioTimingService
import Foundation
import QuranAudio
import QuranKit
import Utilities
import VLogging

/// Reports the word under the playhead as the reciter moves through a sura.
///
/// Driven by the player's own clock rather than by a timer started at an ayah boundary,
/// so pause, resume, seek, repeat and playback rate need no handling of their own.
@MainActor
final class RecitationWordFollower {
    // MARK: Lifecycle

    init(retriever: ReciterWordSegmentRetriever) {
        self.retriever = retriever
    }

    // MARK: Internal

    /// Called only when the word changes, so callers need not deduplicate.
    var onWordChanged: (@MainActor (Word?) -> Void)?

    /// Called with whether feeding the playhead in would move anything.
    var onFollowingChanged: (@MainActor (Bool) -> Void)?

    /// False while suspended, so a caller that stops observing the playhead on this cannot
    /// be undone by the next ayah boundary.
    var isFollowing: Bool {
        !isSuspended && loaded?.isEmpty == false
    }

    /// Loads the sura's word segments, if the reciter has any.
    ///
    /// State is invalidated synchronously, before the load suspends, so a playhead update
    /// arriving mid-load finds no timeline rather than the previous sura's.
    func playing(ayah: AyahNumber, reciter: Reciter?) {
        guard let reciter else {
            stop()
            return
        }
        quran = ayah.quran
        let sura = ayah.sura
        let request = Request(database: reciter.localDatabasePath, sura: sura)
        guard requested != request else {
            return
        }
        requested = request
        loaded = nil
        loadTask?.cancel()
        loadTask = Task { [retriever, weak self] in
            do {
                let timeline = try await retriever.wordSegments(for: reciter, sura: sura)
                guard !Task.isCancelled, let self, requested == request else {
                    return
                }
                loaded = timeline
                onFollowingChanged?(isFollowing)
                logger.info("WordFollower: \(timeline.segments.count) word segments for \(sura)")
            } catch {
                logger.error("WordFollower: couldn't load word segments for \(sura): \(error)")
                guard let self, requested == request else {
                    return
                }
                // Clear the marker so the next ayah boundary retries.
                requested = nil
                onFollowingChanged?(false)
            }
        }
    }

    func playbackTime(_ seconds: TimeInterval) {
        guard !isSuspended, let quran, let loaded, seconds.isFinite else {
            return
        }
        guard let segment = loaded.segment(atMillis: Int(seconds * 1000)),
              let verse = AyahNumber(quran: quran, sura: segment.sura, ayah: segment.ayah)
        else {
            // Between two words, or an ayah the data does not cover. Hold the last
            // highlight rather than flickering it off.
            return
        }
        emit(Word(verse: verse, wordNumber: segment.position))
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
        requested = nil
        loaded = nil
        quran = nil
        isSuspended = false
        emit(nil)
        onFollowingChanged?(false)
    }

    /// Stops moving the highlight without unloading the sura, for when nobody can see it.
    func suspend() {
        isSuspended = true
        onFollowingChanged?(isFollowing)
    }

    func resume() {
        isSuspended = false
        onFollowingChanged?(isFollowing)
    }

    // MARK: Private

    /// Keyed on the database file, because that is what decides the timings; reciter
    /// metadata can churn on a catalogue refresh. Gapped reciters all compare equal, which
    /// is right — none of them has timings.
    private struct Request: Equatable {
        let database: RelativeFilePath?
        let sura: Sura
    }

    private let retriever: ReciterWordSegmentRetriever

    private var quran: Quran?
    private var requested: Request?
    private var loaded: WordSegmentTimeline?
    private var loadTask: Task<Void, Never>?
    private var isSuspended = false
    private var lastWord: Word?

    private func emit(_ word: Word?) {
        guard word != lastWord else {
            return
        }
        lastWord = word
        onWordChanged?(word)
    }
}
