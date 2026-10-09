//
//  QuranVerseNumber.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import Localization
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

/// The verse-number capsule shown in translation mode.
///
/// In sync builds it shows the verse's annotation badges and opens the verse menu when tapped.
public struct QuranVerseNumber: View {
    // MARK: Lifecycle

    #if QURAN_SYNC
    public init(verse: AyahNumber, annotations: Set<AyahAnnotation>, onTapped: @escaping (CGPoint) -> Void) {
        self.verse = verse
        self.annotations = annotations
        self.onTapped = onTapped
    }
    #else
    public init(verse: AyahNumber) {
        self.verse = verse
    }
    #endif

    // MARK: Public

    public var body: some View {
        #if QURAN_SYNC
        Button {
            onTapped(CGPoint(x: capsuleFrame.midX, y: capsuleFrame.midY))
        } label: {
            touchTarget(
                capsule
                    .onGlobalFrameChanged { capsuleFrame = $0 }
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("translation-ayah-number-\(verse.sura.suraNumber)-\(verse.ayah)")
        #else
        capsule
        #endif
    }

    // MARK: Internal

    let verse: AyahNumber

    /// A capsule that sits inside a line of translation text.
    ///
    /// An inline capsule is only as tall as a line of text. It keeps a touch target close to the minimum
    /// without growing its layout frame or reaching over the text around it: at most
    /// `maximumHorizontalOutset` past its sides and a few points below it.
    ///
    /// - Parameter size: The capsule's `inlineSize(dynamicTypeSize:legibilityWeight:)`.
    func inline(size: CGSize, maximumHorizontalOutset: CGFloat) -> Self {
        var copy = self
        copy.inlineLayout = InlineLayout(size: size, maximumHorizontalOutset: maximumHorizontalOutset)
        return copy
    }

    /// The size of the inline capsule, computed from the fonts and metrics it renders with,
    /// so text can make room for it in the same layout pass.
    func inlineSize(dynamicTypeSize: DynamicTypeSize, legibilityWeight: LegibilityWeight?) -> CGSize {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.contentSizeCategory),
            UITraitCollection(legibilityWeight: legibilityWeight == .bold ? .bold : .regular),
        ])
        let font = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traits)
        let fontMetrics = UIFontMetrics(forTextStyle: .footnote)
        func scaled(_ value: CGFloat) -> CGFloat {
            fontMetrics.scaledValue(for: value, compatibleWith: traits)
        }

        var contentWidth = ceil((numberText as NSString).size(withAttributes: [.font: font]).width)
        #if QURAN_SYNC
        if !annotations.isEmpty {
            let count = CGFloat(annotations.count)
            contentWidth += Self.dividerWidth + count * scaled(Metrics.annotationSize) + (count + 1) * scaled(Metrics.spacing)
        }
        #endif

        return CGSize(
            width: contentWidth + 2 * scaled(Metrics.inlineHorizontalPadding),
            height: ceil(font.lineHeight) + 2 * scaled(Metrics.inlineVerticalPadding)
        )
    }

    // MARK: Private

    private enum Metrics {
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 6
        static let inlineHorizontalPadding: CGFloat = 9
        static let inlineVerticalPadding: CGFloat = 2
        static let spacing: CGFloat = 8
        static let annotationSize: CGFloat = 13
    }

    private struct InlineLayout {
        let size: CGSize
        let maximumHorizontalOutset: CGFloat
    }

    private static let minimumTouchLength: CGFloat = 44
    /// Keeps the touch area off the first words of the next line of text.
    private static let maximumBottomOutset: CGFloat = 3
    private static let dividerWidth: CGFloat = 1

    @ScaledMetric(relativeTo: .footnote) private var horizontalPadding = Metrics.horizontalPadding
    @ScaledMetric(relativeTo: .footnote) private var verticalPadding = Metrics.verticalPadding
    @ScaledMetric(relativeTo: .footnote) private var inlineHorizontalPadding = Metrics.inlineHorizontalPadding
    @ScaledMetric(relativeTo: .footnote) private var inlineVerticalPadding = Metrics.inlineVerticalPadding
    @ScaledMetric(relativeTo: .footnote) private var spacing = Metrics.spacing
    @ScaledMetric(relativeTo: .footnote) private var annotationSize = Metrics.annotationSize

    /// Set for an inline capsule. See `inline(size:maximumHorizontalOutset:)`.
    private var inlineLayout: InlineLayout?

    #if QURAN_SYNC
    private let annotations: Set<AyahAnnotation>
    private let onTapped: (CGPoint) -> Void
    @State private var capsuleFrame: CGRect = .zero
    #endif

    private var isInline: Bool {
        inlineLayout != nil
    }

    private var numberText: String {
        lFormat("translation.text.ayah-number", verse.sura.suraNumber, verse.ayah)
    }

    @ViewBuilder
    private func touchTarget(_ content: some View) -> some View {
        if let inlineLayout {
            let size = inlineLayout.size
            let verticalOutset = max(0, Self.minimumTouchLength - size.height)
            let bottom = min(verticalOutset / 2, Self.maximumBottomOutset)
            content
                .contentShape(OutsetRectangle(
                    horizontal: min(max(0, (Self.minimumTouchLength - size.width) / 2), inlineLayout.maximumHorizontalOutset),
                    top: verticalOutset - bottom,
                    bottom: bottom
                ))
        } else {
            content
                .minimumTouchTarget()
        }
    }

    private var capsule: some View {
        HStack(spacing: spacing) {
            Text(numberText)
            #if QURAN_SYNC
            if !annotations.isEmpty {
                Divider()
                    .frame(width: Self.dividerWidth, height: annotationSize)
                ForEach(annotations.ordered) { annotation in
                    AyahAnnotationIcon(annotation: annotation, size: annotationSize)
                }
            }
            #endif
        }
        .font(.footnote)
        .fixedSize()
        .padding(.horizontal, isInline ? inlineHorizontalPadding : horizontalPadding)
        .padding(.vertical, isInline ? inlineVerticalPadding : verticalPadding)
        .themedSecondaryForeground()
        .themedSecondaryBackground()
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// A rectangle grown past its frame, to extend a touch area without changing layout.
private struct OutsetRectangle: Shape {
    let horizontal: CGFloat
    let top: CGFloat
    let bottom: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(
            x: rect.minX - horizontal,
            y: rect.minY - top,
            width: rect.width + 2 * horizontal,
            height: rect.height + top + bottom
        ))
    }
}

#if QURAN_SYNC
#Preview("Verse number and annotations") {
    VStack(alignment: .leading, spacing: 0) {
        ForEach([Set<AyahAnnotation>(), [.note], [.readingBookmark(.teal), .readingBookmark(.orange), .collection, .note]], id: \.self) { annotations in
            QuranVerseNumber(
                verse: Quran.hafsMadani1405.suras[1].verses[7],
                annotations: annotations,
                onTapped: { _ in }
            )
        }
    }
    .padding()
    .themedBackground()
}
#else
#Preview("Verse number") {
    QuranVerseNumber(verse: Quran.hafsMadani1405.suras[1].verses[7])
        .padding()
        .themedBackground()
}
#endif
