#if QURAN_SYNC
//
//  MobileSyncAyahHighlightService.swift
//

@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit
import Utilities

public struct MobileSyncAyahHighlightService {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService, quran: Quran) {
        self.quranDataService = quranDataService
        self.quran = quran
    }

    // MARK: Public

    public func highlightsSequence() -> AnyAsyncSequence<[AyahNumber: HighlightColor]> {
        let quran = quran
        let sequence = quranDataService.highlightsSequence()
            .map { highlights in
                highlights.reduce(into: [AyahNumber: HighlightColor]()) { result, highlight in
                    guard let ayah = AyahNumber(
                        quran: quran,
                        sura: Int(highlight.sura),
                        ayah: Int(highlight.ayah)
                    ), let color = HighlightColor(highlight.color) else {
                        return
                    }
                    result[ayah] = color
                }
            }
        return .init(sequence)
    }

    public func setHighlight(_ color: HighlightColor, for ayahs: [AyahNumber]) async throws {
        for ayah in ayahs {
            _ = try await quranDataService.setAyahHighlight(
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah),
                color: color.mobileSyncColor
            )
        }
    }

    public func removeHighlight(for ayahs: [AyahNumber]) async throws {
        for ayah in ayahs {
            _ = try await quranDataService.removeAyahHighlight(
                sura: Int32(ayah.sura.suraNumber),
                ayah: Int32(ayah.ayah)
            )
        }
    }

    // MARK: Private

    private let quranDataService: QuranDataService
    private let quran: Quran
}

private extension HighlightColor {
    init?(_ color: AyahHighlightColor) {
        switch color {
        case .blue: self = .blue
        case .red: self = .red
        case .green: self = .green
        case .yellow: self = .yellow
        case .purple: self = .purple
        default: return nil
        }
    }

    var mobileSyncColor: AyahHighlightColor {
        switch self {
        case .blue: .blue
        case .red: .red
        case .green: .green
        case .yellow: .yellow
        case .purple: .purple
        }
    }
}
#endif
