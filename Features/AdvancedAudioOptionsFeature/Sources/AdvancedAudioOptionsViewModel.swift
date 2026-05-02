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
        self.options = options
        self.reciterListBuilder = reciterListBuilder
        reciter = options.reciter
        fromVerse = options.start
        toVerse = options.end
        verseRuns = options.verseRuns
        listRuns = options.listRuns
        playbackRate = AudioPreferences.shared.playbackRate
        endAt = Self.deduceEndAt(from: options.start, to: options.end)

        AudioPreferences.shared.$playbackRate.assign(to: &$playbackRate)
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

    var suras: [Sura] {
        options.start.quran.suras
    }

    func play() {
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
        toVerse = to
        if to < fromVerse {
            fromVerse = to
        }
        endAt = .custom
    }

    func setEndAt(_ choice: EndAtChoice) {
        endAt = choice
        applyEndAt()
    }

    // MARK: - Updating Playback Rate

    func updatePlaybackRate(to rate: Float) {
        AudioPreferences.shared.playbackRate = rate
    }

    // MARK: Private

    private let options: AdvancedAudioOptions
    private let reciterListBuilder: ReciterListBuilder

    // An end ayah can coincide with multiple boundaries (end of Al-Fatihah is
    // also end of page 1). We prefer surah → juz → page → quran to match how
    // users mentally pick a range.
    private static func deduceEndAt(from start: AyahNumber, to end: AyahNumber) -> EndAtChoice {
        let priority: [EndAtChoice] = [.surah, .juz, .page, .quran]
        for choice in priority {
            guard let audioEnd = choice.audioEnd else { continue }
            if audioEnd.lastAyahFinder.findLastAyah(startAyah: start) == end {
                return choice
            }
        }
        return .custom
    }

    private func applyEndAt() {
        guard let audioEnd = endAt.audioEnd else { return }
        toVerse = audioEnd.lastAyahFinder.findLastAyah(startAyah: fromVerse)
    }

    private func currentOptions() -> AdvancedAudioOptions {
        return AdvancedAudioOptions(
            reciter: reciter,
            start: fromVerse,
            end: toVerse,
            verseRuns: verseRuns,
            listRuns: listRuns
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

extension AudioEnd {
    var lastAyahFinder: any LastAyahFinder {
        switch self {
        case .page: return PageBasedLastAyahFinder()
        case .juz: return JuzBasedLastAyahFinder()
        case .quran: return QuranBasedLastAyahFinder()
        case .sura: return SuraBasedLastAyahFinder()
        }
    }
}
