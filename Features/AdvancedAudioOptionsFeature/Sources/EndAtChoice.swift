//
//  EndAtChoice.swift
//  Quran
//

import Localization
import QuranAudio
import QuranKit

enum EndAtChoice: Hashable, CaseIterable {
    case page
    case surah
    case juz
    case quran
    case custom

    static let pickerChoices: [EndAtChoice] = [.custom, .page, .surah, .juz, .quran]

    var audioEnd: AudioEnd? {
        switch self {
        case .page: return .page
        case .surah: return .sura
        case .juz: return .juz
        case .quran: return .quran
        case .custom: return nil
        }
    }

    var localizedName: String {
        switch self {
        case .custom: return l("audio.end-at.custom")
        default: return audioEnd?.name ?? ""
        }
    }
}
