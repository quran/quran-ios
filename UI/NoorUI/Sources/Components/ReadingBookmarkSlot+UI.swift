#if QURAN_SYNC
import QuranAnnotations
import SwiftUI
import UIKit

public extension ReadingBookmarkSlot {
    var displayName: String {
        switch self {
        case .coral:
            "Coral"
        case .teal:
            "Teal"
        case .indigo:
            "Indigo"
        }
    }

    var color: UIColor {
        switch self {
        case .coral:
            UIColor(red: 0.91, green: 0.31, blue: 0.20, alpha: 1)
        case .teal:
            .systemTeal
        case .indigo:
            .systemIndigo
        }
    }

    var swiftUIColor: Color {
        Color(color)
    }
}
#endif
