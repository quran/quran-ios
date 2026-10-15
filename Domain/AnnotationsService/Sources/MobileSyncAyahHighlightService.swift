#if QURAN_SYNC
//
//  MobileSyncAyahHighlightService.swift
//

import MobileSync
import QuranAnnotations
import QuranKit
import ReadingService
import Utilities

public struct MobileSyncAyahHighlightService {
    // MARK: Lifecycle

    public init(
        quranDataService: MobileSyncDataService,
        readingPreferences: ReadingPreferences = .shared
    ) {
        self.quranDataService = quranDataService
        self.readingPreferences = readingPreferences
    }

    // MARK: Public

    public func highlightsSequence() -> AnyAsyncSequence<[AyahNumber: HighlightColor]> {
        let readingPreferences = readingPreferences
        let sequence = quranDataService.highlightsSequence()
            .map { highlights in
                highlights.reduce(into: [AyahNumber: HighlightColor]()) { result, highlight in
                    guard let ayah = AyahNumber(
                        quran: readingPreferences.reading.quran,
                        sura: highlight.sura,
                        ayah: highlight.ayah
                    ) else {
                        return
                    }
                    result[ayah] = HighlightColor(highlight.color)
                }
            }
        return .init(sequence)
    }

    public func setHighlight(_ color: HighlightColor, for ayahs: [AyahNumber]) async throws {
        for ayah in ayahs {
            _ = try await quranDataService.setAyahHighlight(
                sura: ayah.sura.suraNumber,
                ayah: ayah.ayah,
                color: color.mobileSyncColor
            )
        }
    }

    public func removeHighlight(for ayahs: [AyahNumber]) async throws {
        for ayah in ayahs {
            _ = try await quranDataService.deleteAyahHighlight(
                sura: ayah.sura.suraNumber,
                ayah: ayah.ayah
            )
        }
    }

    // MARK: Private

    private let quranDataService: MobileSyncDataService
    private let readingPreferences: ReadingPreferences
}

private extension HighlightColor {
    init(_ color: MobileSyncHighlightColor) {
        switch color {
        case .blue: self = .blue
        case .pink: self = .pink
        case .green: self = .green
        case .yellow: self = .yellow
        case .purple: self = .purple
        }
    }

    var mobileSyncColor: MobileSyncHighlightColor {
        switch self {
        case .blue: .blue
        case .pink: .pink
        case .green: .green
        case .yellow: .yellow
        case .purple: .purple
        }
    }
}
#endif
