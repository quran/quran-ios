import Localization
import SwiftUI
import UIx

struct AudioOptionsButton: View {
    let summary: AudioOptionsSummary
    let action: () -> Void

    @ScaledMetric private var dotSize = 8
    @ScaledMetric private var dotBorder = 2
    @ScaledMetric(relativeTo: .caption2) private var summarySpacing = 2

    @State private var summaryTextHeight: CGFloat = 0
    @State private var imageSize: CGSize = .zero
    @State private var buttonSize: CGSize = .zero

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
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize()
                                    .frame(width: geometry.size.width, alignment: .trailing)
                                    .offset(x: -imageSize.width / 2, y: geometry.size.height)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                                    .onGeometryValueChange(of: \.size.height) { summaryTextHeight = $0 }
                            }
                        }
                    }
                    .onGeometryValueChange(of: \.size) { imageSize = $0 }
                    .padding()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l("audio.options"))
        .accessibilityValue(summary.text)
        .onGeometryValueChange(of: \.size) { buttonSize = $0 }
        .padding(.vertical, summary.hasNonDefaultValues ? summaryPadding : 0)
    }

    var summaryPadding: CGFloat {
        summaryTextHeight - (buttonSize.height - imageSize.height) / 2 + summarySpacing
    }
}
