//
//  AccentCapsuleButton.swift
//

import SwiftUI

/// A compact button filled with the app tint, for the one action of a card or an empty state.
public struct AccentCapsuleButton: View {
    // MARK: Lifecycle

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.onAccent)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(Color.accentColor, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    @ScaledMetric private var horizontalPadding = 14.0
    @ScaledMetric private var verticalPadding = 7.0

    private let title: String
    private let action: () -> Void
}
