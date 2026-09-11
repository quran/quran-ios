import Foundation
import Localization
import QuranAudio

public struct AudioOptionsSummary: Equatable {
    public init(rate: Float = 1, verseRuns: Runs = .finite(1), rangeRuns: Runs = .finite(1)) {
        self.rate = rate
        self.verseRuns = verseRuns
        self.rangeRuns = rangeRuns
    }

    public let rate: Float
    public let verseRuns: Runs
    public let rangeRuns: Runs

    public var hasNonDefaultValues: Bool {
        rate != 1 || verseRuns != .finite(1) || rangeRuns != .finite(1)
    }

    public var text: String {
        var parts: [String] = []
        if rate != 1 {
            parts.append(PlaybackSpeed.formatted(rate))
        }
        if verseRuns != .finite(1) {
            parts.append(String(format: l("audio.summary.verse"), count(verseRuns)))
        }
        if rangeRuns != .finite(1) {
            parts.append(String(format: l("audio.summary.range"), count(rangeRuns)))
        }
        return parts.joined(separator: " · ")
    }

    private func count(_ runs: Runs) -> String {
        switch runs {
        case .finite(let count): return "×" + NumberFormatter.shared.format(count)
        case .indefinite: return "∞"
        }
    }
}
