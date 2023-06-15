//
//  AdvancedAudioViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine

public protocol AdvancedAudioUISura {
    associatedtype Verse: AdvancedAudioUIVerse
    var localizedName: String { get }
    var verses: [Verse] { get }
}

public protocol AdvancedAudioUIVerse: Equatable {
    var localizedName: String { get }
    var localizedNameWithSuraNumber: String { get }
}

public enum AdvancedAudioUI {
    public enum AudioRepeat: Int {
        case none
        case once
        case twice
        case indefinite

        static var sorted: [AudioRepeat] {
            [.none, .once, .twice, .indefinite]
        }
    }

    public struct Actions {
        let reciterTapped: () -> Void
        let lastPageTapped: () -> Void
        let lastSuraTapped: () -> Void
        let lastJuzTapped: () -> Void
        let fromVerseTapped: () -> Void
        let toVerseTapped: () -> Void
        public init(reciterTapped: @escaping () -> Void,
                    lastPageTapped: @escaping () -> Void,
                    lastSuraTapped: @escaping () -> Void,
                    lastJuzTapped: @escaping () -> Void,
                    fromVerseTapped: @escaping () -> Void,
                    toVerseTapped: @escaping () -> Void)
        {
            self.reciterTapped = reciterTapped
            self.lastPageTapped = lastPageTapped
            self.lastSuraTapped = lastSuraTapped
            self.lastJuzTapped = lastJuzTapped
            self.fromVerseTapped = fromVerseTapped
            self.toVerseTapped = toVerseTapped
        }
    }

    public class DataObject<Sura: AdvancedAudioUISura>: ObservableObject {
        public init(suras: [Sura],
                    fromVerse: Sura.Verse,
                    toVerse: Sura.Verse,
                    verseRepeat: AdvancedAudioUI.AudioRepeat,
                    listRepeat: AdvancedAudioUI.AudioRepeat,
                    reciterName: String)
        {
            self.suras = suras
            _fromVerse = Published(initialValue: fromVerse)
            _toVerse = Published(initialValue: toVerse)
            _verseRepeat = Published(initialValue: verseRepeat)
            _listRepeat = Published(initialValue: listRepeat)
            _reciterName = Published(initialValue: reciterName)
        }

        public let suras: [Sura]
        @Published public var fromVerse: Sura.Verse
        @Published public var toVerse: Sura.Verse
        @Published public var verseRepeat: AdvancedAudioUI.AudioRepeat
        @Published public var listRepeat: AdvancedAudioUI.AudioRepeat
        @Published public var reciterName: String
    }
}
