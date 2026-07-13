//
//  NoorListEmptyState.swift
//

import SwiftUI
import UIx

public struct NoorListEmptyState: View {
    public init(title: String, text: String, image: NoorSystemImage) {
        self.title = title
        self.text = text
        self.image = image
    }

    public var body: some View {
        VStack(spacing: 8) {
            image.image
                .font(.title)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.secondaryLabel)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .accessibilityElement(children: .combine)
    }

    private let title: String
    private let text: String
    private let image: NoorSystemImage
}
