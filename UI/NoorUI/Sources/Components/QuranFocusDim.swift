//
//  QuranFocusDim.swift
//

import SwiftUI

/// Covers a Quran page with its theme background, leaving the `cutouts` fully visible.
public struct QuranFocusDim: View {
    // MARK: Lifecycle

    public init(cutouts: [CGRect]) {
        self.cutouts = cutouts
    }

    // MARK: Public

    public static let opacity = 0.75

    public var body: some View {
        Rectangle()
            .fill(themeColors.background.opacity(Self.opacity))
            .overlay {
                QuranHighlightShape(lineRects: cutouts)
                    .fill(Color.black)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }

    // MARK: Private

    @Environment(\.themeColors) private var themeColors

    private let cutouts: [CGRect]
}

#Preview {
    Text(String(repeating: "Quran ", count: 200))
        .overlay {
            QuranFocusDim(cutouts: [
                CGRect(x: 20, y: 60, width: 200, height: 24),
                CGRect(x: 20, y: 84, width: 120, height: 24),
            ])
        }
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
}
