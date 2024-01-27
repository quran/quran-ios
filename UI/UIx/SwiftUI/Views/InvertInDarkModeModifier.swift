//
//  InvertInDarkModeModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import SwiftUI

private struct InvertInDarkModeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.colorInvert()
        } else {
            content
        }
    }
}

extension View {
    public func invertInDarkMode() -> some View {
        modifier(InvertInDarkModeModifier())
    }
}
