//
//  AyahIndicatorsView.swift
//

#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import SwiftUI

public struct AyahIndicatorsView: View {
    public init(
        markers: [AyahMarkerPlacement],
        indicators: [AyahNumber: Set<AyahIndicator>],
        indicatorsHidden: Bool,
        onAyahIndicatorTap: @escaping (AyahNumber, CGPoint) -> Void
    ) {
        self.markers = markers
        self.indicators = indicators
        self.indicatorsHidden = indicatorsHidden
        self.onAyahIndicatorTap = onAyahIndicatorTap
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(indicatedPlacements, id: \.ayah) { placement in
                let rectangle = placement.frame

                AyahIndicatorsButton(
                    ayah: placement.ayah,
                    indicators: indicators[placement.ayah, default: []],
                    size: rectangle.height,
                    action: { onAyahIndicatorTap(placement.ayah, $0) }
                )
                .position(x: rectangle.midX, y: rectangle.midY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
        .opacity(indicatorsHidden ? 0 : 1)
        .animation(NoorAnimation.standard, value: indicatorsHidden)
        .allowsHitTesting(!indicatorsHidden)
        .accessibilityHidden(indicatorsHidden)
    }

    private let indicatorsHidden: Bool
    private let markers: [AyahMarkerPlacement]
    private let indicators: [AyahNumber: Set<AyahIndicator>]
    private let onAyahIndicatorTap: (AyahNumber, CGPoint) -> Void

    private var indicatedPlacements: [AyahMarkerPlacement] {
        markers.filter { indicators[$0.ayah]?.isEmpty == false }
    }
}

private struct AyahIndicatorsPlacementPreview: View {
    var body: some View {
        VStack {
            Text("Dashed rectangles show marker frames. The third has no indicators.")
                .font(.caption)

            ZStack(alignment: .topLeading) {
                ForEach(markers, id: \.ayah) { placement in
                    Rectangle()
                        .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: placement.frame.width, height: placement.frame.height)
                        .position(x: placement.frame.midX, y: placement.frame.midY)
                }
            }
            .frame(width: 280, height: 240)
            .allowsHitTesting(false)
            .overlay {
                AyahIndicatorsView(
                    markers: markers,
                    indicators: [ayahs[0]: [.note], ayahs[1]: [.collection, .note]],
                    indicatorsHidden: false,
                    onAyahIndicatorTap: { ayah, _ in tappedAyah = ayah }
                )
            }

            Text(tappedAyah.map { "Tapped ayah \($0.ayah)" } ?? "Tap an indicator")
                .font(.footnote)
        }
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
    }

    @State private var tappedAyah: AyahNumber?
    private let ayahs = Array(Quran.hafsMadani1405.suras[1].verses.prefix(3))

    private var markers: [AyahMarkerPlacement] {
        [
            AyahMarkerPlacement(ayah: ayahs[0], frame: CGRect(x: 200, y: 20, width: 40, height: 40)),
            AyahMarkerPlacement(ayah: ayahs[1], frame: CGRect(x: 60, y: 100, width: 60, height: 60)),
            AyahMarkerPlacement(ayah: ayahs[2], frame: CGRect(x: 180, y: 180, width: 40, height: 40)),
        ]
    }
}

#Preview("Indicator placement") {
    AyahIndicatorsPlacementPreview()
}

#endif
