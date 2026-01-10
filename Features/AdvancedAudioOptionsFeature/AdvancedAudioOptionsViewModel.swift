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
    }

    // MARK: Internal

    weak var listener: AdvancedAudioOptionsListener?

    @Published var fromVerse: AyahNumber
    @Published var toVerse: AyahNumber
    @Published var verseRuns: Runs
    @Published var listRuns: Runs
    @Published var reciter: Reciter

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

    // MARK: - Updating Last Ayah

    func updateFromVerseTo(_ from: AyahNumber) {
        fromVerse = from
        if toVerse < from {
            toVerse = from
        }
    }

    func updateToVerseTo(_ to: AyahNumber) {
        toVerse = to
        if to < fromVerse {
            fromVerse = to
        }
    }

    func setLastVerseInPage() {
        setLastVerse(using: PageBasedLastAyahFinder())
    }

    func setLastVerseInJuz() {
        setLastVerse(using: JuzBasedLastAyahFinder())
    }

    func setLastVerseInSura() {
        for sura in suras {
            if sura.verses.contains(fromVerse) {
                updateToVerseTo(sura.verses.last!)
            }
        }
    }

    func setLastVerseInQuran() {
        setLastVerse(using: QuranBasedLastAyahFinder())
    }

    // MARK: Private

    private let options: AdvancedAudioOptions
    private let reciterListBuilder: ReciterListBuilder

    private func setLastVerse(using finder: LastAyahFinder) {
        let verse = finder.findLastAyah(startAyah: fromVerse)
        updateToVerseTo(verse)
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
