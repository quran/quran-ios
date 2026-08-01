//
//  NoorTag.swift
//

import SwiftUI

public struct NoorTag: Hashable {
    public enum Tone: String, Codable {
        case accent
        case neutral
        case yellow
        case red
    }

    public let title: String
    public let tone: Tone

    public init(title: String, tone: Tone) {
        self.title = title
        self.tone = tone
    }
}

public struct NoorTagView: View {
    @ScaledMetric private var dotSize = 6.0

    private let tag: NoorTag

    public init(_ tag: NoorTag) {
        self.tag = tag
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)

            Text(tag.title)
                .font(.caption2.bold())
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(backgroundColor))
    }

    private var foregroundColor: Color {
        switch tag.tone {
        case .accent:
            return .accentColor
        case .neutral:
            return Color(uiColor: .secondaryLabel)
        case .yellow:
            return .orange
        case .red:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch tag.tone {
        case .accent:
            return Color.accentColor.opacity(0.1)
        case .neutral:
            return Color(uiColor: .secondaryLabel).opacity(0.1)
        case .yellow:
            return Color.yellow.opacity(0.15)
        case .red:
            return Color.red.opacity(0.1)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        NoorTagView(NoorTag(title: "Optimized", tone: .accent))
        NoorTagView(NoorTag(title: "Informational", tone: .neutral))
        NoorTagView(NoorTag(title: "Attention", tone: .yellow))
        NoorTagView(NoorTag(title: "Experimental", tone: .red))
    }
    .padding()
}
