#if QURAN_SYNC
//
//  AyahIndicatorsButton.swift
//

import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIKit
import UIx

struct AyahIndicatorsButton: View {
    let ayah: AyahNumber
    let indicators: Set<AyahIndicator>
    let size: CGFloat
    let action: (CGPoint) -> Void

    var body: some View {
        Button {
            action(CGPoint(x: globalFrame.midX, y: globalFrame.midY))
        } label: {
            AyahIndicatorsLabel(indicators: indicators.markerIndicators, size: size)
                .minimumTouchTarget()
        }
        .buttonStyle(AyahIndicatorsButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("ayah-indicators-\(ayah.sura.suraNumber)-\(ayah.ayah)")
        .onGlobalFrameChanged { globalFrame = $0 }
    }

    @State private var globalFrame: CGRect = .zero

    var accessibilityLabel: String {
        ([ayah.localizedName] + indicators.ordered.map(\.accessibilityLabel)).joined(separator: l("list.separator"))
    }
}

private struct AyahIndicatorsLabel: View {
    // MARK: Internal

    let indicators: [AyahIndicator]
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(indicators.enumerated()), id: \.element) { index, indicator in
                layer(indicator)
                    .offset(y: size * 0.06 + CGFloat(index) * size * 0.24)
                    .zIndex(Double(indicators.count - index))
            }
        }
        .frame(width: size, height: size)
        // One shadow for the whole stack.
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
    }

    // MARK: Private

    @Environment(\.themeColors) private var themeColors

    private var gray: Color { Color(UIColor.systemGray) }

    @ViewBuilder
    private func layer(_ indicator: AyahIndicator) -> some View {
        switch indicator {
        case .readingBookmark(let slot):
            symbol(.bookmark, color: slot.swiftUIColor, scale: 0.98)
        case .collection:
            symbol(.starFilled, color: gray, scale: 0.84)
        case .note:
            Circle()
                .fill(gray)
                .overlay {
                    NoorSystemImage.note.image
                        .font(.system(size: size * 0.46, weight: .bold))
                        .foregroundStyle(themeColors.background)
                }
                .frame(width: size * 0.92, height: size * 0.92)
        }
    }

    private func symbol(_ image: NoorSystemImage, color: Color, scale: CGFloat) -> some View {
        image.image
            .font(.system(size: size * scale, weight: .semibold))
            .foregroundStyle(color)
    }
}

private struct AyahIndicatorsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct AyahIndicatorsButtonPreview: View {
    var body: some View {
        VStack(alignment: .leading) {
            previewRow("Note", indicators: [.note])
            previewRow("Collection", indicators: [.collection])
            previewRow("Reading bookmarks", indicators: readingBookmarks)
            previewRow("Bookmark wins", indicators: readingBookmarks.union([.collection, .note]))
            previewRow("Note wins", indicators: [.collection, .note])
            previewRow("Small marker", indicators: [.note], size: 12)

            Text("Dashed outlines show touch targets.")
                .font(.caption)
            Text("Taps: \(tapCount)")
                .monospacedDigit()
        }
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
    }

    @State private var tapCount = 0
    private let ayah = Quran.hafsMadani1405.suras[1].verses[4]
    @ScaledMetric private var markerSize = 28.0

    private var readingBookmarks: Set<AyahIndicator> {
        Set(ReadingBookmarkSlot.allCases.map { .readingBookmark($0) })
    }

    private func previewRow(_ title: String, indicators: Set<AyahIndicator>, size: CGFloat? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            AyahIndicatorsButton(
                ayah: ayah,
                indicators: indicators,
                size: size ?? markerSize,
                action: { _ in tapCount += 1 }
            )
            .overlay {
                Rectangle()
                    .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .allowsHitTesting(false)
            }
        }
    }
}

#Preview("Indicator buttons") {
    AyahIndicatorsButtonPreview()
}
#endif
