//
//  AdvancedAudioOptionsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import Localization
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit

@MainActor
public protocol AdvancedAudioOptionsListener: AnyObject {
    func updateAudioOptions(to newOptions: AdvancedAudioOptions)
    func dismissAudioOptions()
}

@MainActor
final class AdvancedAudioOptionsInteractor {
    // MARK: Lifecycle

    init(options: AdvancedAudioOptions) {
        self.options = options
        reciter = options.reciter

        let advancedAudioSuras = Self.surasToAdvancedAudioSuras(options.start.quran.suras)
        dataObject = AdvancedAudioUI.DataObject(
            suras: advancedAudioSuras,
            fromVerse: Self.verseToAdvancedAudioVerse(options.start),
            toVerse: Self.verseToAdvancedAudioVerse(options.end),
            verseRepeat: AdvancedAudioUI.AudioRepeat(options.verseRuns),
            listRepeat: AdvancedAudioUI.AudioRepeat(options.listRuns),
            reciterName: options.reciter.localizedName
        )
    }

    // MARK: Internal

    weak var listener: AdvancedAudioOptionsListener?

    @Published var dataObject: AdvancedAudioUI.DataObject<ConcreteAdvancedAudioUISura>

    func play() {
        listener?.updateAudioOptions(to: currentOptions())
        dismiss()
    }

    func dismiss() {
        listener?.dismissAudioOptions()
    }

    // MARK: - Updating Last Ayah

    func updateFromVerseTo(_ from: ConcreteAdvancedAudioUIVerse) {
        dataObject.fromVerse = from
        if dataObject.toVerse.verse < from.verse {
            dataObject.toVerse = from
        }
    }

    func updateToVerseTo(_ to: ConcreteAdvancedAudioUIVerse) {
        dataObject.toVerse = to
        if to.verse < dataObject.fromVerse.verse {
            dataObject.fromVerse = to
        }
    }

    func setLastVerseInPage() {
        setLastVerse(using: PageBasedLastAyahFinder())
    }

    func setLastVerseInJuz() {
        setLastVerse(using: JuzBasedLastAyahFinder())
    }

    func setLastVerseInSura() {
        for sura in dataObject.suras {
            if sura.verses.contains(dataObject.fromVerse) {
                updateToVerseTo(sura.verses.last!)
            }
        }
    }

    // MARK: - Reciter List

    func updateReciter(to reciter: Reciter) {
        self.reciter = reciter
    }

    // MARK: Private

    private let options: AdvancedAudioOptions

    private var reciter: Reciter {
        didSet {
            dataObject.reciterName = reciter.localizedName
        }
    }

    private static func surasToAdvancedAudioSuras(_ suras: [Sura]) -> [ConcreteAdvancedAudioUISura] {
        var advancedAudioSuras: [ConcreteAdvancedAudioUISura] = []
        for sura in suras {
            let verses = sura.verses
            let advancedAudioVerses = verses.map { Self.verseToAdvancedAudioVerse($0) }
            advancedAudioSuras.append(ConcreteAdvancedAudioUISura(sura: sura, verses: advancedAudioVerses))
        }
        return advancedAudioSuras
    }

    private static func verseToAdvancedAudioVerse(_ verse: AyahNumber) -> ConcreteAdvancedAudioUIVerse {
        ConcreteAdvancedAudioUIVerse(verse: verse)
    }

    private func setLastVerse(using finder: LastAyahFinder) {
        let startVerse = dataObject.fromVerse.verse
        let verse = finder.findLastAyah(startAyah: startVerse)
        updateToVerseTo(Self.verseToAdvancedAudioVerse(verse))
    }

    private func currentOptions() -> AdvancedAudioOptions {
        let from = dataObject.fromVerse.verse
        let to = dataObject.toVerse.verse
        return AdvancedAudioOptions(
            reciter: reciter,
            start: from,
            end: to,
            verseRuns: dataObject.verseRepeat.run,
            listRuns: dataObject.listRepeat.run
        )
    }
}

private extension AdvancedAudioUI.AudioRepeat {
    var run: Runs {
        switch self {
        case .none:
            return .one
        case .once:
            return .two
        case .twice:
            return .three
        case .indefinite:
            return .indefinite
        }
    }
}

private extension AdvancedAudioUI.AudioRepeat {
    init(_ runs: Runs) {
        switch runs {
        case .one:
            self = .none
        case .two:
            self = .once
        case .three:
            self = .twice
        case .four, .indefinite:
            self = .indefinite
        }
    }
}

struct ConcreteAdvancedAudioUIVerse: Hashable, AdvancedAudioUIVerse {
    let verse: AyahNumber

    var localizedName: String {
        verse.localizedName
    }

    var localizedNameWithSuraNumber: String {
        verse.localizedNameWithSuraNumber
    }
}

struct ConcreteAdvancedAudioUISura: AdvancedAudioUISura {
    let sura: Sura
    let verses: [ConcreteAdvancedAudioUIVerse]

    var localizedName: String {
        sura.localizedName()
    }
}
