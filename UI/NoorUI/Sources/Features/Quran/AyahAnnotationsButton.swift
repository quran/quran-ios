#if QURAN_SYNC
//
//  AyahAnnotationsButton.swift
//

import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

struct AyahAnnotationsButton: View {
    let ayah: AyahNumber
    let annotations: Set<AyahAnnotation>
    let height: CGFloat
    let action: (CGPoint) -> Void

    var body: some View {
        Button {
            action(CGPoint(x: globalFrame.midX, y: globalFrame.midY))
        } label: {
            AyahAnnotationsLabel(annotations: annotations, height: height)
                .frame(minWidth: minimumTargetSize, minHeight: minimumTargetSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(AyahAnnotationsButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("ayah-annotations-\(ayah.sura.suraNumber)-\(ayah.ayah)")
        .onGlobalFrameChanged { globalFrame = $0 }
    }

    @State private var globalFrame: CGRect = .zero
    @ScaledMetric private var minimumTargetSize = 44.0

    var accessibilityLabel: String {
        ([ayah.localizedName] + annotations.ordered.map(\.accessibilityLabel)).joined(separator: ", ")
    }
}

private struct AyahAnnotationsLabel: View {
    let annotations: Set<AyahAnnotation>
    let height: CGFloat

    var body: some View {
        HStack(spacing: height * 0.14) {
            ForEach(annotations.ordered) { annotation in
                annotationIcon(annotation)
            }
        }
        .font(.system(size: height * 0.48, weight: .semibold))
        .frame(height: height)
        .padding(.horizontal, height * 0.28)
        .background {
            Capsule()
                .fill(Color(themeStyle.backgroundColor))
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
        }
    }

    @Environment(\.themeStyle) private var themeStyle

    private func annotationIcon(_ annotation: AyahAnnotation) -> some View {
        Group {
            switch annotation {
            case .readingBookmark(let bookmark):
                Image(uiImage: ReadingBookmarkPin.image(style: .filled))
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(bookmark.swiftUIColor)
            case .collection:
                NoorSystemImage.bookmark.image
                    .foregroundStyle(Color(themeStyle.secondaryTextColor))
            case .note:
                NoorSystemImage.note.image
                    .foregroundStyle(Color(themeStyle.secondaryTextColor))
            }
        }
        .symbolRenderingMode(.monochrome)
        .frame(width: height * 0.52, height: height * 0.52)
    }
}

private struct AyahAnnotationsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct AyahAnnotationsButtonPreview: View {
    var body: some View {
        VStack(alignment: .leading) {
            previewRow("Note", annotations: [.note])
            previewRow("Collection", annotations: [.collection])
            previewRow("Reading bookmarks", annotations: readingBookmarks)
            previewRow("Combined", annotations: readingBookmarks.union([.collection, .note]))
            previewRow("Small badge", annotations: [.note], height: 8)

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

    private var readingBookmarks: Set<AyahAnnotation> {
        Set(ReadingBookmarkSlot.allCases.map { .readingBookmark($0) })
    }

    private func previewRow(_ title: String, annotations: Set<AyahAnnotation>, height: CGFloat? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            AyahAnnotationsButton(
                ayah: ayah,
                annotations: annotations,
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

#Preview("Annotation buttons") {
    AyahAnnotationsButtonPreview()
}
#endif
