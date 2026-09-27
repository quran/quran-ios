#if QURAN_SYNC
import Localization
import QuranAnnotations
import SwiftUI
import UIKit

public extension ReadingBookmarkSlot {
    /// Slots share the highlight color names.
    var displayName: String {
        switch self {
        case .green:
            l("highlight.color.green")
        case .purple:
            l("highlight.color.purple")
        case .blue:
            l("highlight.color.blue")
        }
    }

    var color: UIColor {
        switch self {
        case .green:
            .systemGreen
        case .purple:
            .systemPurple
        case .blue:
            .systemBlue
        }
    }

    var swiftUIColor: Color {
        Color(color)
    }
}
#endif
