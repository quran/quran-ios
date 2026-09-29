#if QURAN_SYNC
import Localization
import QuranAnnotations
import SwiftUI
import UIKit

public extension ReadingBookmarkSlot {
    /// Slots share the highlight color names.
    var displayName: String {
        switch self {
        case .teal:
            l("highlight.color.teal")
        case .orange:
            l("highlight.color.orange")
        case .red:
            l("highlight.color.red")
        }
    }

    var color: UIColor {
        switch self {
        case .teal:
            .systemTeal
        case .orange:
            .systemOrange
        case .red:
            .systemRed
        }
    }

    var swiftUIColor: Color {
        Color(color)
    }
}
#endif
