import QuranAnnotations
import SwiftUI
import UIx

public struct HighlightPaletteIcon: View {
    @ScaledMetric private var trailingPadding = ContentDimension.interSpacing
    @ScaledMetric private var purpleOffset = ContentDimension.interSpacing
    @ScaledMetric private var blueOffset = ContentDimension.interSpacing / 2
    @ScaledMetric private var shadowRadius = ContentDimension.interSpacing / 8
    @ScaledMetric private var minLength = ContentDimension.interPageSpacing + ContentDimension.interSpacing

    public init(addsTrailingPadding: Bool = false) {
        self.addsTrailingPadding = addsTrailingPadding
    }

    public var body: some View {
        ZStack {
            HighlightPaletteCircle(color: .purple, minLength: minLength)
                .offset(x: purpleOffset)
            HighlightPaletteCircle(color: .blue, minLength: minLength)
                .offset(x: blueOffset)
            HighlightPaletteCircle(color: .green, minLength: minLength)
        }
        .frame(width: minLength + purpleOffset, alignment: .leading)
        .compositingGroup()
        .shadow(color: Color.tertiarySystemGroupedBackground, radius: shadowRadius)
        .padding(.trailing, addsTrailingPadding ? trailingPadding : 0)
    }

    private let addsTrailingPadding: Bool
}

private struct HighlightPaletteCircle: View {
    let color: HighlightColor
    let minLength: CGFloat

    var body: some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}
