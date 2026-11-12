import Localization
import QuranAnnotations
import SwiftUI
import UIKit

extension HighlightColor {
    // MARK: Public

    public var uiColor: UIColor {
        switch self {
        case .pink: return #colorLiteral(red: 0.9976003766, green: 0.6918323636, blue: 0.790571034, alpha: 1)
        case .green: return #colorLiteral(red: 0.7582061887, green: 0.9266348481, blue: 0.441752553, alpha: 1)
        case .blue: return #colorLiteral(red: 0.6776656508, green: 0.8418365121, blue: 0.994728744, alpha: 1)
        case .yellow: return #colorLiteral(red: 0.9911049008, green: 0.9235726595, blue: 0.3886876702, alpha: 1)
        case .purple: return #colorLiteral(red: 0.8482968211, green: 0.695538938, blue: 0.9965527654, alpha: 1)
        }
    }

    public var color: SwiftUI.Color {
        SwiftUI.Color(uiColor)
    }

    public var localizedName: String {
        switch self {
        case .pink: return l("highlight.color.pink")
        case .green: return l("highlight.color.green")
        case .blue: return l("highlight.color.blue")
        case .yellow: return l("highlight.color.yellow")
        case .purple: return l("highlight.color.purple")
        }
    }

    /// Every color, the one used by the most `highlights` first. Ties go alphabetically by localized name.
    public static func sortedByUsage(in highlights: some Sequence<HighlightColor>) -> [Self] {
        let counts = Dictionary(highlights.map { ($0, 1) }, uniquingKeysWith: +)
        return allCases.sorted { lhs, rhs in
            let lhsCount = counts[lhs, default: 0]
            let rhsCount = counts[rhs, default: 0]
            if lhsCount != rhsCount {
                return lhsCount > rhsCount
            }
            return lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
        }
    }
}
