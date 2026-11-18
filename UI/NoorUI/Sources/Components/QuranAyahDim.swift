//
//  QuranAyahDim.swift
//

import SwiftUI

/// Dims a Quran page except for `cutouts`.
public struct QuranAyahDim: View {
    // MARK: Lifecycle

    public init(cutouts: [CGRect]) {
        self.cutouts = cutouts
    }

    // MARK: Public

    public var body: some View {
        Rectangle()
            .fill(themeColors.background.opacity(1 - dimmedAyahOpacity))
            .overlay {
                QuranHighlightShape(lineRects: cutouts)
                    .fill(Color.black)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }

    // MARK: Private

    @Environment(\.themeColors) private var themeColors
    @Environment(\.dimmedAyahOpacity) private var dimmedAyahOpacity

    private let cutouts: [CGRect]
}

extension View {
    /// Fades dimmed content to the opacity `QuranAyahDim` leaves Quran page text.
    public func dimmedAyah(_ isDimmed: Bool) -> some View {
        modifier(DimmedAyahModifier(isDimmed: isDimmed))
    }
}

/// A dimmed ayah's opacity: higher on dark pages, where faded text is harder to read, and with Increase Contrast.
enum DimmedAyahOpacity {
    static func value(isDark: Bool, increasesContrast: Bool) -> Double {
        let opacity = isDark ? 0.4 : 0.25
        return increasesContrast ? opacity + 0.15 : opacity
    }
}

extension EnvironmentValues {
    var dimmedAyahOpacity: Double {
        DimmedAyahOpacity.value(
            isDark: quranPageColorScheme == .dark,
            increasesContrast: colorSchemeContrast == .increased
        )
    }
}

private struct DimmedAyahModifier: ViewModifier {
    // MARK: Internal

    let isDimmed: Bool

    func body(content: Content) -> some View {
        content.opacity(isDimmed ? dimmedAyahOpacity : 1)
    }

    // MARK: Private

    @Environment(\.dimmedAyahOpacity) private var dimmedAyahOpacity
}

#Preview {
    Text(String(repeating: "Quran ", count: 200))
        .overlay {
            QuranAyahDim(cutouts: [
                CGRect(x: 20, y: 60, width: 200, height: 24),
                CGRect(x: 20, y: 84, width: 120, height: 24),
            ])
        }
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
}
