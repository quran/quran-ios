//
//  EndAtChoice.swift
//  Quran
//

import Localization
import QuranAudio
import QuranAudioKit
import QuranKit

enum EndAtChoice: Hashable {
    case page
    case surah
    case juz
    case quran
    case custom

    // MARK: Lifecycle

    init(_ audioEnd: AudioEnd) {
        switch audioEnd {
        case .page: self = .page
        case .sura: self = .surah
        case .juz: self = .juz
        case .quran: self = .quran
        }
    }

    // MARK: Internal

    /// The choices the Play up to menu lists. Custom isn't one: editing To picks it.
    static let menuChoices: [EndAtChoice] = AudioEnd.playUpToChoices.map(EndAtChoice.init)

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
