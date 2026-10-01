//
//  AdvancedAudioOptionsViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import QuranTextKit
import ReciterListFeature
import SwiftUI

@MainActor
public protocol AdvancedAudioOptionsListener: AnyObject {
    func updateAudioOptions(to newOptions: AdvancedAudioOptions)
    func dismissAudioOptions()
}

@MainActor
final class AdvancedAudioOptionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        options: AdvancedAudioOptions,
        reciterListBuilder: ReciterListBuilder
    ) {
        let normalizedEnd = max(options.end, options.start)
        self.options = options
        self.reciterListBuilder = reciterListBuilder
        reciter = options.reciter
        fromVerse = options.start
        toVerse = normalizedEnd
        verseRuns = options.verseRuns
        listRuns = options.listRuns
        verseDelay = options.verseDelay
        repetitionDelay = options.repetitionDelay
        playbackRate = AudioPreferences.shared.playbackRate
        endAt = Self.deduceEndAt(
            from: options.start,
            to: normalizedEnd,
            preferred: AudioPreferences.shared.audioEnd
        )
    }

    // MARK: Internal

    weak var listener: AdvancedAudioOptionsListener?

    @Published var fromVerse: AyahNumber
    @Published var toVerse: AyahNumber
    @Published var verseRuns: Runs
    @Published var listRuns: Runs
    @Published var reciter: Reciter
    @Published var endAt: EndAtChoice
    @Published var playbackRate: Float

    @Published var repetitionDelay: RepetitionDelay
    @Published var verseDelay: VerseDelay

    func play() {
        AudioPreferences.shared.playbackRate = playbackRate
        // Only an End at the user picked here becomes the Play up to
        // preference; a deduced one just describes the range they opened.
        if didChooseEndAt, let audioEnd = endAt.audioEnd {
            AudioPreferences.shared.audioEnd = audioEnd
        }
        listener?.updateAudioOptions(to: currentOptions())
        dismiss()
    }

    func dismiss() {
        listener?.dismissAudioOptions()
    }

    // MARK: - Updating Range

    func updateFromVerseTo(_ from: AyahNumber) {
        fromVerse = from
        if endAt == .custom {
            if toVerse < from { toVerse = from }
        } else {
            applyEndAt()
        }
    }

    func updateToVerseTo(_ to: AyahNumber) {
        toVerse = max(to, fromVerse)
        endAt = .custom
    }

    func setEndAt(_ choice: EndAtChoice) {
        endAt = choice
        didChooseEndAt = true
        applyEndAt()
    }

    // MARK: - Play up to Menu

    /// The Play up to menu's checked choice. Custom isn't a menu item, so it checks none.
    var playUpToSelection: EndAtChoice? {
        endAt == .custom ? nil : endAt
    }

    /// Picks a Play up to menu choice. Picking the current choice again changes nothing:
    /// it neither counts as choosing it nor moves To.
    func selectPlayUpTo(_ choice: EndAtChoice) {
        guard choice != endAt else { return }
        setEndAt(choice)
    }

    // MARK: - Updating Playback Rate

    func updatePlaybackRate(to rate: Float) {
        playbackRate = rate
    }

    // MARK: Private

    private let options: AdvancedAudioOptions
    private let reciterListBuilder: ReciterListBuilder
    private var didChooseEndAt = false

    // The saved Play up to preference wins when it explains the range, so the
    // sheet opens on the choice the banner used to fill it.
    //
    // Otherwise, an end ayah can coincide with multiple boundaries (end of
    // Al-Fatihah is also end of page 1, and every juz' ends a hizb and a ¼ hizb).
    // We prefer surah → juz → hizb → quarter → page → quran to match how users
    // mentally pick a range, with the bigger unit winning when ends coincide.
    private static func deduceEndAt(from start: AyahNumber, to end: AyahNumber, preferred: AudioEnd) -> EndAtChoice {
        if matches(preferred, start: start, end: end) {
            return EndAtChoice(preferred)
        }

        let priority: [EndAtChoice] = [.surah, .juz, .hizb, .quarter, .page, .quran]
        for choice in priority {
            guard let audioEnd = choice.audioEnd else { continue }
            if matches(audioEnd, start: start, end: end) {
                return choice
            }
        }
        return .custom
    }

    // Choices here and in the banner end on the page-floored boundary, while
    // ranges picked verse by verse (e.g. a whole surah from the ayah menu) can
    // end on the boundary itself; both describe the choice. ¼ Hizb and Hizb
    // aren't floored, so only their exact boundary matches.
    private static func matches(_ audioEnd: AudioEnd, start: AyahNumber, end: AyahNumber) -> Bool {
        end == audioEnd.boundaryLastAyahFinder.findLastAyah(startAyah: start)
            || end == AudioEndLastAyahFinder(audioEnd: audioEnd).findLastAyah(startAyah: start)
    }

    private func applyEndAt() {
        guard let audioEnd = endAt.audioEnd else { return }
        toVerse = AudioEndLastAyahFinder(audioEnd: audioEnd).findLastAyah(startAyah: fromVerse)
    }

    private func currentOptions() -> AdvancedAudioOptions {
        return AdvancedAudioOptions(
            reciter: reciter,
            start: fromVerse,
            end: toVerse,
            verseRuns: verseRuns,
            listRuns: listRuns,
            verseDelay: verseDelay,
            repetitionDelay: repetitionDelay
        )
    }
}

extension AdvancedAudioOptionsViewModel: ReciterListListener {
    func recitersViewController() -> UIViewController {
        reciterListBuilder.build(withListener: self, standalone: false)
    }

    func onSelectedReciterChanged(to reciter: Reciter) {
        self.reciter = reciter
    }
}
