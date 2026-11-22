//
//  QuranIDButton.swift
//

import Localization
import SwiftUI
import UIKit
import UIx

/// "Sign in with Quran ID" in Quran Foundation's partner-kit colours, as a label for `.buttonStyle(.quranID)`.
///
/// Quran Foundation approved this native rendition of the kit's fixed English artwork, so it follows the app
/// language and Dynamic Type.
public struct QuranIDButtonLabel: View {
    // MARK: Lifecycle

    public init(style: Style = .adaptive, isInProgress: Bool = false) {
        self.init(l("quran_id.sign_in"), style: style, size: .regular, isInProgress: isInProgress)
    }

    /// VoiceOver reads "Sign in with Quran ID" whatever the visible `title`.
    init(
        _ title: String,
        style: Style = .adaptive,
        size: Size = .regular,
        isInProgress: Bool = false
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isInProgress = isInProgress
        let textStyle = size.textStyle
        _markSize = ScaledMetric(wrappedValue: size.markSize, relativeTo: textStyle)
        _markInset = ScaledMetric(wrappedValue: size.markInset, relativeTo: textStyle)
        _spacing = ScaledMetric(wrappedValue: size.spacing, relativeTo: textStyle)
        _trailingPadding = ScaledMetric(wrappedValue: size.trailingPadding, relativeTo: textStyle)
    }

    // MARK: Public

    public enum Style {
        /// Quran ID Dark in light mode and Quran ID Green in dark mode.
        case adaptive
        /// White with a Quran ID Dark edge, for dark or busy surfaces that don't follow the appearance.
        case white
    }

    public var body: some View {
        let colors = colors
        HStack(spacing: spacing) {
            colors.mark.image
                .resizable()
                .scaledToFit()
                .frame(width: markSize, height: markSize)

            Text(title)
                .font(size.font)
                .foregroundStyle(colors.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, markInset)
        .padding(.trailing, trailingPadding)
        .padding(.vertical, markInset)
        .background(colors.fill, in: shape)
        .overlay {
            if let border = colors.border {
                shape.strokeBorder(border, lineWidth: 1)
            }
        }
        .opacity(isInProgress ? 0.5 : 1)
        // A fade, without motion, so it stays under Reduce Motion.
        .animation(NoorAnimation.standard, value: isInProgress)
        .frame(minHeight: Self.minimumTapHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityTitle)
        .accessibilityValue(isInProgress ? lAndroid("loading") : "")
        // Voice Control matches the visible title too, such as "Sign In" in a toast.
        .accessibilityInputLabels(inputLabels)
    }

    // MARK: Internal

    enum Size {
        /// For the main action of a card or a screen.
        case regular
        /// For a toast's action, with a short title such as "Sign In".
        case compact
    }

    // MARK: Private

    private struct Colors {
        let fill: Color
        let text: Color
        let border: Color?
        let mark: NoorImage
    }

    /// The kit's colours. They belong to the Quran ID brand, so they stay out of the app's palette.
    private static let quranIDGreen = Color(UIColor(rgb: 0x1BDAA5))
    private static let quranIDDark = Color(UIColor(rgb: 0x003223))

    /// The smallest comfortable tap target; the compact capsule is shorter and keeps it around itself.
    private static let minimumTapHeight: CGFloat = 44

    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric private var markSize: CGFloat
    @ScaledMetric private var markInset: CGFloat
    @ScaledMetric private var spacing: CGFloat
    @ScaledMetric private var trailingPadding: CGFloat

    private let title: String
    private let style: Style
    private let size: Size
    private let isInProgress: Bool

    private static var accessibilityTitle: String { l("quran_id.sign_in") }

    private var inputLabels: [Text] {
        let titles = title == Self.accessibilityTitle ? [title] : [title, Self.accessibilityTitle]
        return titles.map { Text($0) }
    }

    /// A capsule while the title fits on one line, and a rounded rectangle with the same end radius once it wraps.
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: markSize / 2 + markInset, style: .continuous)
    }

    private var colors: Colors {
        switch style {
        case .adaptive where colorScheme == .dark:
            Colors(fill: Self.quranIDGreen, text: Self.quranIDDark, border: nil, mark: .quranIDMark)
        case .adaptive:
            Colors(fill: Self.quranIDDark, text: Self.quranIDGreen, border: nil, mark: .quranIDMarkOnDark)
        case .white:
            Colors(fill: .white, text: Self.quranIDDark, border: Self.quranIDDark, mark: .quranIDMark)
        }
    }
}

/// The partner kit's press feedback.
public struct QuranIDButtonStyle: ButtonStyle {
    // MARK: Lifecycle

    init() {}

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.04 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            // The kit's quick ease-out, which keeps up with the finger better than the standard animation.
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }

    // MARK: Private

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
}

extension ButtonStyle where Self == QuranIDButtonStyle {
    public static var quranID: QuranIDButtonStyle { QuranIDButtonStyle() }
}

private extension QuranIDButtonLabel.Size {
    var textStyle: Font.TextStyle {
        switch self {
        case .regular: .headline
        case .compact: .subheadline
        }
    }

    var font: Font {
        switch self {
        case .regular: .headline.weight(.medium)
        case .compact: .subheadline.weight(.semibold)
        }
    }

    var markSize: CGFloat {
        switch self {
        case .regular: 36
        case .compact: 22
        }
    }

    /// The space around the mark, which sets the capsule's height with it.
    var markInset: CGFloat {
        switch self {
        case .regular: 6
        case .compact: 5
        }
    }

    var spacing: CGFloat {
        switch self {
        case .regular: 10
        case .compact: 6
        }
    }

    var trailingPadding: CGFloat {
        switch self {
        case .regular: 20
        case .compact: 12
        }
    }
}

#Preview("Light and dark") {
    VStack(spacing: 0) {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            VStack(spacing: 16) {
                Button {} label: { QuranIDButtonLabel() }
                Button {} label: { QuranIDButtonLabel("Sign In", size: .compact) }
            }
            .buttonStyle(.quranID)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.systemGroupedBackground)
            .environment(\.colorScheme, scheme)
        }
    }
}

#Preview("White") {
    Button {} label: { QuranIDButtonLabel(style: .white) }
        .buttonStyle(.quranID)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(rgb: 0x000A48)))
}

#Preview("Accessibility size") {
    VStack(spacing: 16) {
        Button {} label: { QuranIDButtonLabel() }
        Button {} label: { QuranIDButtonLabel("Sign In", size: .compact) }
    }
    .buttonStyle(.quranID)
    .padding()
    .dynamicTypeSize(.accessibility3)
}
