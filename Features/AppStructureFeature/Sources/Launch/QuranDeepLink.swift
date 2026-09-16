//
//  QuranDeepLink.swift
//  Quran
//
//  Created by Abdullah Levin on 2026-09-06.
//

import Foundation
import QuranAudio
import QuranKit

enum QuranDeepLinkTarget: Equatable {
    case sura(Sura)
    case ayah(AyahNumber)
}

struct QuranDeepLinkAudio: Equatable {
    let end: AyahNumber?
    let verseRuns: Runs
    let listRuns: Runs
    let reciterId: Int?
    let playbackRate: Float?
}

struct QuranDeepLink: Equatable {
    let target: QuranDeepLinkTarget
    let audio: QuranDeepLinkAudio?
}

extension QuranDeepLink {
    // MARK: Lifecycle

    /// Parses links of the form `quran://sura` and `quran://sura/ayah`, matching the
    /// format handled by `QuranForwarderActivity` on Android. Non numeric segments are
    /// skipped, so `quran://sura/2/255` resolves the same way `quran://2/255` does.
    ///
    /// Audio playback query parameters (`play`, `to`, `verse_repeat`, `range_repeat`,
    /// `reciter`, `speed`) are only parsed when `play` is present and truthy; otherwise
    /// they are ignored entirely and `audio` is `nil`.
    init?(url: URL, quran: Quran) {
        guard let scheme = url.scheme?.lowercased(), Self.supportedSchemes.contains(scheme) else {
            return nil
        }

        let numbers = Self.segments(of: url).compactMap { Int($0) }
        guard let suraNumber = numbers.first, let sura = Sura(quran: quran, suraNumber: suraNumber) else {
            return nil
        }

        let target: QuranDeepLinkTarget
        if numbers.count > 1 {
            guard let ayah = AyahNumber(sura: sura, ayah: numbers[1]) else {
                return nil
            }
            target = .ayah(ayah)
        } else {
            target = .sura(sura)
        }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard Self.isPlayEnabled(queryItems) else {
            self.target = target
            audio = nil
            return
        }

        guard let audio = Self.audio(for: target, queryItems: queryItems) else {
            return nil
        }
        self.target = target
        self.audio = audio
    }

    // MARK: Private

    private static let supportedSchemes: Set<String> = ["quran", "quran-ios"]
    private static let repeatRange = 1 ... 100
    private static let playbackRateRange: ClosedRange<Float> = 0.25 ... 2.0

    /// The authority of `quran://2/255` is the sura, so it is read from the host and
    /// not from the path.
    private static func segments(of url: URL) -> [String] {
        var segments: [String] = []
        if let host = url.host, !host.isEmpty {
            segments.append(host)
        }
        segments.append(contentsOf: url.pathComponents.filter { $0 != "/" })
        return segments
    }

    private static func value(_ name: String, in queryItems: [URLQueryItem]) -> String? {
        queryItems.first { $0.name == name }?.value
    }

    private static func isPlayEnabled(_ queryItems: [URLQueryItem]) -> Bool {
        guard let play = value("play", in: queryItems)?.lowercased() else {
            return false
        }
        return play == "true" || play == "1"
    }

    private static func audio(for target: QuranDeepLinkTarget, queryItems: [URLQueryItem]) -> QuranDeepLinkAudio? {
        try? parseAudio(for: target, queryItems: queryItems)
    }

    private static func parseAudio(
        for target: QuranDeepLinkTarget, queryItems: [URLQueryItem]
    ) throws -> QuranDeepLinkAudio {
        QuranDeepLinkAudio(
            end: try end(for: target, queryItems: queryItems),
            verseRuns: try runs(named: "verse_repeat", in: queryItems),
            listRuns: try runs(named: "range_repeat", in: queryItems),
            reciterId: try reciterId(in: queryItems),
            playbackRate: try playbackRate(in: queryItems)
        )
    }

    private static func runs(named name: String, in queryItems: [URLQueryItem]) throws -> Runs {
        guard let rawValue = value(name, in: queryItems) else {
            return .finite(1)
        }
        if rawValue.lowercased() == "infinite" {
            return .indefinite
        }
        guard let count = Int(rawValue), repeatRange.contains(count) else {
            throw AudioParameterError.invalid
        }
        return .finite(count)
    }

    private static func end(for target: QuranDeepLinkTarget, queryItems: [URLQueryItem]) throws -> AyahNumber? {
        guard let rawValue = value("to", in: queryItems) else {
            return nil
        }

        let components = rawValue.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count == 2,
              let suraNumber = Int(components[0]),
              let ayahNumber = Int(components[1])
        else {
            throw AudioParameterError.invalid
        }

        let quran: Quran
        let start: AyahNumber
        switch target {
        case .sura(let sura):
            quran = sura.quran
            start = sura.firstVerse
        case .ayah(let ayah):
            quran = ayah.quran
            start = ayah
        }

        guard let sura = Sura(quran: quran, suraNumber: suraNumber),
              let endAyah = AyahNumber(sura: sura, ayah: ayahNumber),
              endAyah >= start
        else {
            throw AudioParameterError.invalid
        }
        return endAyah
    }

    private static func reciterId(in queryItems: [URLQueryItem]) throws -> Int? {
        guard let rawValue = value("reciter", in: queryItems) else {
            return nil
        }
        guard let reciterId = Int(rawValue), reciterId >= 1 else {
            throw AudioParameterError.invalid
        }
        return reciterId
    }

    private static func playbackRate(in queryItems: [URLQueryItem]) throws -> Float? {
        guard let rawValue = value("speed", in: queryItems) else {
            return nil
        }
        guard let playbackRate = Float(rawValue), playbackRateRange.contains(playbackRate) else {
            throw AudioParameterError.invalid
        }
        return playbackRate
    }
}

private enum AudioParameterError: Error {
    case invalid
}
