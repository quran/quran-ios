//
//  DynamicTypeSize+ContentSizeCategory.swift
//
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import SwiftUI
import UIKit

extension DynamicTypeSize {
    /// The UIKit content size category for this size, to measure UIKit fonts the way SwiftUI renders them.
    var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}
