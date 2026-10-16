#if QURAN_SYNC
//
//  AyahIndicatorsButton.swift
//

import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

struct AyahIndicatorsButton: View {
    let ayah: AyahNumber
    let indicators: Set<AyahIndicator>
    let height: CGFloat
    let action: (CGPoint) -> Void

    var body: some View {
        Button {
            action(CGPoint(x: globalFrame.midX, y: globalFrame.midY))
        } label: {
            AyahIndicatorsLabel(indicators: indicators, height: height)
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
    let indicators: Set<AyahIndicator>
    let height: CGFloat

    var body: some View {
        HStack(spacing: height * 0.14) {
            ForEach(indicators.ordered) { indicator in
                AyahIndicatorIcon(indicator: indicator)
            }
        }
        .font(.system(size: height * 0.48, weight: .semibold))
        .frame(height: height)
        .padding(.horizontal, height * 0.28)
        .background {
            Capsule()
                .fill(themeColors.background)
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
        }
    }

    @Environment(\.themeColors) private var themeColors
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
            previewRow("Combined", indicators: readingBookmarks.union([.collection, .note]))
            previewRow("Small badge", indicators: [.note], height: 8)

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
    @ScaledMetric private var badgeHeight = 20.0

    private var readingBookmarks: Set<AyahIndicator> {
        Set(ReadingBookmarkSlot.allCases.map { .readingBookmark($0) })
    }

    private func previewRow(_ title: String, indicators: Set<AyahIndicator>, height: CGFloat? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            AyahIndicatorsButton(
                ayah: ayah,
                indicators: indicators,
                height: height ?? badgeHeight,
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
