//
//  AyahAnnotationsView.swift
//

#if QURAN_SYNC
import QuranAnnotations
import QuranKit
import SwiftUI

public struct AyahAnnotationsView: View {
    private static let heightScale: CGFloat = 0.62

    public init(
        markers: [AyahMarkerPlacement],
        annotations: [AyahNumber: Set<AyahAnnotation>],
        annotationsHidden: Bool,
        onAnnotatedAyahTap: @escaping (AyahNumber, CGPoint) -> Void
    ) {
        self.markers = markers
        self.annotations = annotations
        self.annotationsHidden = annotationsHidden
        self.onAnnotatedAyahTap = onAnnotatedAyahTap
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(annotatedPlacements, id: \.ayah) { placement in
                let rectangle = placement.frame
                let buttonHeight = rectangle.height * Self.heightScale

                AyahAnnotationsButton(
                    ayah: placement.ayah,
                    annotations: annotations[placement.ayah, default: []],
                    height: buttonHeight,
                    action: { onAnnotatedAyahTap(placement.ayah, $0) }
                )
                .position(x: rectangle.midX, y: rectangle.maxY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
        .opacity(annotationsHidden ? 0 : 1)
        .animation(ReaderVisibilityAnimation.animation, value: annotationsHidden)
        .allowsHitTesting(!annotationsHidden)
        .accessibilityHidden(annotationsHidden)
    }

    private let annotationsHidden: Bool
    private let markers: [AyahMarkerPlacement]
    private let annotations: [AyahNumber: Set<AyahAnnotation>]
    private let onAnnotatedAyahTap: (AyahNumber, CGPoint) -> Void

    private var annotatedPlacements: [AyahMarkerPlacement] {
        markers.filter { annotations[$0.ayah]?.isEmpty == false }
    }
}

private struct AyahAnnotationsPlacementPreview: View {
    var body: some View {
        VStack {
            Text("Dashed rectangles show marker frames. The third has no annotations.")
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
                AyahAnnotationsView(
                    markers: markers,
                    annotations: [ayahs[0]: [.note], ayahs[1]: [.collection, .note]],
                    annotationsHidden: false,
                    onAnnotatedAyahTap: { ayah, _ in tappedAyah = ayah }
                )
            }

            Text(tappedAyah.map { "Tapped ayah \($0.ayah)" } ?? "Tap an annotation")
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

#Preview("Annotation placement") {
    AyahAnnotationsPlacementPreview()
}

#endif
