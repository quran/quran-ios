import Localization
import SwiftUI

struct AudioOptionsButton: View {
    let summary: AudioOptionsSummary
    let action: () -> Void

    @ScaledMetric private var dotSize = 8
    @ScaledMetric private var dotBorder = 2
    @ScaledMetric(relativeTo: .caption2) private var summarySpacing = 2

    var body: some View {
        // The size depends only on the content and the proposal. Measuring the button to size it
        // never converges at large text sizes and freezes the reader.
        ZStack {
            if summary.hasNonDefaultValues {
                // Reserves a summary line above and below the icon to keep it centered.
                VStack(spacing: 0) {
                    summaryLine
                    icon
                    summaryLine
                }
                .padding(.vertical, summarySpacing)
                .hidden()
                .accessibilityHidden(true)
            }

            Button(action: action) {
                AudioControlLabel {
                    // Secondary to the transport controls, so it stays neutral and leaves the tint to them.
                    icon
                        .foregroundStyle(.primary)
                        .overlay(alignment: .topTrailing) {
                            if summary.hasNonDefaultValues {
                                dot
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if summary.hasNonDefaultValues {
                                // Hangs from the icon's bottom center toward the leading side.
                                summaryText
                                    .frame(width: 0, height: 0, alignment: .topTrailing)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l("audio.options"))
            .accessibilityValue(summary.text)
        }
    }

    private var icon: some View {
        NoorSystemImage.audioOptions.image
    }

    private var dot: some View {
        Circle()
            .fill(.red.opacity(1.0))
            .frame(width: dotSize, height: dotSize)
            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: dotBorder))
            .accessibilityHidden(true)
    }

    private var summaryText: some View {
        Text(summary.text)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .fixedSize()
    }

    /// A summary line's height without its width, so the summary never widens the button.
    private var summaryLine: some View {
        summaryText
            .frame(width: 0)
    }
}
