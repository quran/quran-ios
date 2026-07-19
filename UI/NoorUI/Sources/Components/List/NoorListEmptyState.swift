//
//  NoorListEmptyState.swift
//

import SwiftUI
import UIx

public struct NoorListEmptyState: View {
    public enum Style {
        case standard
        case prominent(imageColor: Color)
    }

    public init(
        title: String,
        text: String,
        image: NoorSystemImage,
        style: Style = .standard
    ) {
        self.title = title
        self.text = text
        self.image = image
        self.style = style
    }

    public var body: some View {
        switch style {
        case .standard:
            standardContent
        case .prominent(let imageColor):
            prominentContent(imageColor: imageColor)
        }
    }

    private var standardContent: some View {
        VStack {
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
        .padding()
        .accessibilityElement(children: .combine)
    }

    private func prominentContent(imageColor: Color) -> some View {
        VStack {
            image.image
                .font(.system(size: prominentImageSize, weight: .semibold))
                .foregroundStyle(imageColor)
                .padding(.bottom)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Color.primary)

            Text(text)
                .font(.body)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: prominentTextMaxWidth)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    @ScaledMetric(relativeTo: .title) private var prominentImageSize: CGFloat = 42
    @ScaledMetric(relativeTo: .body) private var prominentTextMaxWidth: CGFloat = 300

    private let title: String
    private let text: String
    private let image: NoorSystemImage
    private let style: Style
}
