//
//  TextAlignmentModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import Foundation
import SwiftUI

extension View {
    public func textAlignment(follows characterDirection: Locale.LanguageDirection) -> some View {
        multilineTextAlignment(characterDirection.textAlignment)
            .frame(maxWidth: .infinity, alignment: characterDirection.alignment)
            .environment(\.layoutDirection, .leftToRight)
    }
}

private extension Locale.LanguageDirection {
    var alignment: Alignment {
        self == .rightToLeft ? .trailing : .leading
    }

    var textAlignment: TextAlignment {
        self == .rightToLeft ? .trailing : .leading
    }
}
