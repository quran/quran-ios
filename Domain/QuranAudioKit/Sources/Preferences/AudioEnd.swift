//
//  AudioEnd.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import Foundation
import Localization

public enum AudioEnd: Int {
    case sura
    case juz
    case page
}

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
