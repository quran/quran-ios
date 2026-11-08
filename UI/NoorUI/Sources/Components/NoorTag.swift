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
    public enum Style {
        /// A dot and tinted text on a faint tint of the tone.
        case tinted
        /// Text on a solid fill of the tone, without a dot.
        case filled
    }

    @ScaledMetric private var dotSize = 6.0

    private let tag: NoorTag
    private let style: Style

    public init(_ tag: NoorTag, style: Style = .tinted) {
        self.tag = tag
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 6) {
            if style == .tinted {
                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .accessibilityHidden(true)
            }

            Text(tag.title)
                .font(.caption2.bold())
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(style == .filled ? filledForegroundColor : foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(style == .filled ? foregroundColor : backgroundColor))
    }

    private var filledForegroundColor: Color {
        tag.tone == .accent ? .onAccent : .white
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
        NoorTagView(NoorTag(title: "New", tone: .accent), style: .filled)
    }
    .padding()
}
