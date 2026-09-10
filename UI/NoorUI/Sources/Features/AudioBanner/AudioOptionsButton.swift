import Localization
import SwiftUI

struct AudioOptionsButton: View {
    let summary: AudioOptionsSummary
    let action: () -> Void

    @ScaledMetric private var dotSize = 8
    @ScaledMetric private var dotBorder = 2
    @ScaledMetric(relativeTo: .caption) private var summarySpacing = 4
    @ScaledMetric(relativeTo: .caption) private var summaryPadding = 24

    var body: some View {
        Button(action: action) {
            AudioControlLabel {
                NoorSystemImage.more.image
                    .foregroundStyle(.tint)
                    .overlay(alignment: .topTrailing) {
                        if summary.hasNonDefaultValues {
                            Circle()
                                .fill(.red.opacity(1.0))
                                .frame(width: dotSize, height: dotSize)
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: dotBorder))
                                .accessibilityHidden(true)
                        }
                    }
                    .overlay {
                        if summary.hasNonDefaultValues {
                            GeometryReader { geometry in
                                Text(summary.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                                    .frame(width: geometry.size.width, alignment: .trailing)
                                    .offset(y: geometry.size.height + summarySpacing)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l("audio.options"))
        .accessibilityValue(summary.text)
        .padding(.vertical, summary.hasNonDefaultValues ? summaryPadding : 0)
    }
}
