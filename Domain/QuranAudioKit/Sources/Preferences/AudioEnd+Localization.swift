//
//  AudioEnd+Localization.swift
//
//
//  Created by Mohamed Afifi on 2023-06-11.
//

import Localization
import QuranAudio

extension AudioEnd {
    /// The Play up to menu's choices, in the order every Play up to menu lists them.
    public static let playUpToChoices: [AudioEnd] = [.page, .juz, .sura, .quran]

    public var name: String {
        switch self {
        case .juz:
            return lAndroid("quran_juz2")
        case .sura:
            return l("surah")
        case .page:
            return lAndroid("quran_page")
        case .quran:
            return l("quran_alquran")
        }
    }
}
