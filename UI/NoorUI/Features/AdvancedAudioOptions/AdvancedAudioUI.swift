//
//  AdvancedAudioUI.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import UIx

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
    public struct Actions {
        // MARK: Lifecycle

        public init(
            reciterTapped: @escaping AsyncAction,
            lastPageTapped: @escaping AsyncAction,
            lastSuraTapped: @escaping AsyncAction,
            lastJuzTapped: @escaping AsyncAction,
            fromVerseTapped: @escaping AsyncAction,
            toVerseTapped: @escaping AsyncAction
        ) {
            self.reciterTapped = reciterTapped
            self.lastPageTapped = lastPageTapped
            self.lastSuraTapped = lastSuraTapped
            self.lastJuzTapped = lastJuzTapped
            self.fromVerseTapped = fromVerseTapped
            self.toVerseTapped = toVerseTapped
        }

        // MARK: Internal

        let reciterTapped: AsyncAction
        let lastPageTapped: AsyncAction
        let lastSuraTapped: AsyncAction
        let lastJuzTapped: AsyncAction
        let fromVerseTapped: AsyncAction
        let toVerseTapped: AsyncAction
    }

    // MARK: Public

    public enum AudioRepeat: Int {
        case none
        case once
        case twice
        case indefinite

        // MARK: Internal

        static var sorted: [AudioRepeat] {
            [.none, .once, .twice, .indefinite]
        }
    }

    public class DataObject<Sura: AdvancedAudioUISura>: ObservableObject {
        // MARK: Lifecycle

        public init(
            suras: [Sura],
            fromVerse: Sura.Verse,
            toVerse: Sura.Verse,
            verseRepeat: AdvancedAudioUI.AudioRepeat,
            listRepeat: AdvancedAudioUI.AudioRepeat,
            reciterName: String
        ) {
            self.suras = suras
            _fromVerse = Published(initialValue: fromVerse)
            _toVerse = Published(initialValue: toVerse)
            _verseRepeat = Published(initialValue: verseRepeat)
            _listRepeat = Published(initialValue: listRepeat)
            _reciterName = Published(initialValue: reciterName)
        }

        // MARK: Public

        public let suras: [Sura]
        @Published public var fromVerse: Sura.Verse
        @Published public var toVerse: Sura.Verse
        @Published public var verseRepeat: AdvancedAudioUI.AudioRepeat
        @Published public var listRepeat: AdvancedAudioUI.AudioRepeat
        @Published public var reciterName: String
    }
}
