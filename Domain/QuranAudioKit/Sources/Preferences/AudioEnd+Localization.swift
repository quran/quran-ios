//
//  AudioEnd+Localization.swift
//
//
//  Created by Mohamed Afifi on 2023-06-11.
//

import Localization
import QuranAudio

extension AudioEnd {
    public var name: String {
        switch self {
        case .juz:
            return lAndroid("quran_juz2")
        case .sura:
            return lAndroid("quran_sura")
        case .page:
            return lAndroid("quran_page")
        }
    }
}
