//
//  QuranDeepLink.swift
//  Quran
//
//  Created by Abdullah Levin on 2026-09-06.
//

import Foundation
import QuranKit

enum QuranDeepLink: Equatable {
    case sura(Sura)
    case ayah(AyahNumber)
}

extension QuranDeepLink {
    // MARK: Lifecycle

    /// Parses links of the form `quran://sura` and `quran://sura/ayah`, matching the
    /// format handled by `QuranForwarderActivity` on Android. Non numeric segments are
    /// skipped, so `quran://sura/2/255` resolves the same way `quran://2/255` does.
    init?(url: URL, quran: Quran) {
        guard let scheme = url.scheme?.lowercased(), Self.supportedSchemes.contains(scheme) else {
            return nil
        }

        let numbers = Self.segments(of: url).compactMap { Int($0) }
        guard let suraNumber = numbers.first, let sura = Sura(quran: quran, suraNumber: suraNumber) else {
            return nil
        }

        guard numbers.count > 1 else {
            self = .sura(sura)
            return
        }
        guard let ayah = AyahNumber(sura: sura, ayah: numbers[1]) else {
            return nil
        }
        self = .ayah(ayah)
    }

    // MARK: Private

    private static let supportedSchemes: Set<String> = ["quran", "quran-ios"]

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
}
