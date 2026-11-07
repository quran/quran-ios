import Localization
import QuranAnnotations
import SwiftUI
import UIx

@MainActor
public struct HighlightColorsView: View {
    public struct Item: Identifiable {
        /// - Parameter canRemoveAll: Whether the tile offers Delete All, such as while one isn't already running.
        public init(color: HighlightColor, count: Int, canRemoveAll: Bool = true) {
            self.color = color
            self.count = count
            self.canRemoveAll = canRemoveAll
        }

        public let color: HighlightColor
        public let count: Int
        public let canRemoveAll: Bool
        public var id: HighlightColor { color }
    }

    /// - Parameter removeAll: Gives tiles with highlights a long-press menu that removes them all, outside Edit mode.
    public init(
        items: [Item],
        selectColor: @escaping (HighlightColor) -> Void,
        removeAll: ((HighlightColor) -> Void)? = nil
    ) {
        self.items = items
        self.selectColor = selectColor
        self.removeAll = removeAll
    }

    private let items: [Item]
    private let selectColor: (HighlightColor) -> Void
    private let removeAll: ((HighlightColor) -> Void)?
    @Environment(\.editMode) private var editMode
    @State private var horizontalContentWidth: CGFloat = 0
    @State private var labelWidth: CGFloat = 0
    @ScaledMetric private var spacing = 8
    @ScaledMetric private var inset = 12
    @ScaledMetric private var circleSize = 36
    @ScaledMetric private var cornerRadius = 18

    public var body: some View {
        if !items.isEmpty {
            SingleAxisGeometryReader { width in
                let tileWidth = max(0, (width - spacing * CGFloat(items.count - 1)) / CGFloat(items.count))
                let contentWidth = max(0, tileWidth - inset * 2)
                let horizontal = horizontalContentWidth > 0 && contentWidth >= horizontalContentWidth
                let showsLabel = labelWidth > 0 && contentWidth >= labelWidth

                return HStack(spacing: spacing) {
                    ForEach(items) { item in
                        tile(item) {
                            Group {
                                if horizontal {
                                    horizontalContent(item)
                                } else {
                                    VStack(spacing: spacing * 0.75) {
                                        countCircle(item, size: min(circleSize, contentWidth))
                                        if showsLabel {
                                            label(item)
                                        }
                                    }
                                }
                            }
                            .frame(width: contentWidth)
                            .padding(inset)
                            .contentShape(Rectangle())
                        }
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .accessibilityElement(children: .ignore)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(item.color.localizedName)
                        .accessibilityValue(NumberFormatter.shared.format(item.count))
                        .accessibilityIdentifier("collections.color.\(item.color)")
                        .modifier(DeleteAllAccessibilityAction(deleteAll: removeAllAction(for: item)))
                    }
                }
                // Accept a narrower proposal when rotating back from landscape.
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .overlay {
                measurements
                    .hidden()
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
            .padding(inset)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    /// A tile that offers Delete All presents its own menu on long-press. The list row holds every tile, so a
    /// `contextMenu` on each would become one menu for the whole row, lifting all tiles and using the first one's menu.
    @ViewBuilder
    private func tile(_ item: Item, @ViewBuilder content: () -> some View) -> some View {
        if let removeAll = removeAllAction(for: item) {
            Menu {
                NoorItemMenuItems(open: { selectColor(item.color) }, deleteAll: removeAll)
            } label: {
                content()
            } primaryAction: {
                selectColor(item.color)
            }
            .modifier(TileMenuStyle())
            // The tile is one accessibility element, so activating it opens the color, like tapping it.
            .accessibilityAction { selectColor(item.color) }
        } else {
            Button { selectColor(item.color) } label: {
                content()
            }
            .buttonStyle(BackgroundHighlightingStyle())
        }
    }

    /// Tiles with highlights offer Delete All outside Edit mode.
    private func removeAllAction(for item: Item) -> (@MainActor () -> Void)? {
        // swiftformat:disable:next isEmpty
        guard let removeAll, item.count > 0, item.canRemoveAll, editMode?.wrappedValue.isEditing != true else {
            return nil
        }
        return { removeAll(item.color) }
    }

    private func horizontalContent(_ item: Item) -> some View {
        HStack(spacing: spacing) {
            countCircle(item, size: circleSize)
            Text(item.color.localizedName)
                .font(.body.weight(.semibold))
                .foregroundColor(.label)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    /// The highlight color as a dot with its count inside.
    private func countCircle(_ item: Item, size: CGFloat) -> some View {
        ColoredCircle(color: item.color.color, selected: false, minLength: size)
            .overlay {
                // Size the count from the dot, which already scales with Dynamic Type and shrinks to fit the tile.
                Text(Self.compactCount(item.count))
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .monospacedDigit()
                    // The highlight colors are light in both appearances, so the count stays dark.
                    // Zero is faded but keeps at least 4.5:1 contrast on the lightest color.
                    // swiftformat:disable:next isEmpty
                    .foregroundColor(.black.opacity(item.count > 0 ? 0.85 : 0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(size * 0.12)
            }
    }

    private func label(_ item: Item) -> some View {
        Text(item.color.localizedName)
            .font(.caption)
            .foregroundColor(.secondaryLabel)
            .lineLimit(1)
    }

    /// Formats a count to fit inside the dot: 1,204 becomes "1.2K".
    nonisolated static func compactCount(_ count: Int, locale: Locale = .fixedCurrentLocaleNumbers) -> String {
        count.formatted(.number.notation(.compactName).locale(locale))
    }

    // Measure SwiftUI's actual text, including localization and Dynamic Type, on iOS 15 too.
    private var measurements: some View {
        ZStack {
            VStack {
                ForEach(items) { horizontalContent($0) }
            }
            .fixedSize()
            .onSizeChange { horizontalContentWidth = $0.width }

            VStack {
                ForEach(items) { label($0) }
            }
            .fixedSize()
            .onSizeChange { labelWidth = $0.width }
        }
    }
}

/// Draws a tile's menu like its button, with the same pressed highlight where the system allows it.
private struct TileMenuStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .menuStyle(.button)
                .buttonStyle(BackgroundHighlightingStyle())
        } else {
            content.menuStyle(.borderlessButton)
        }
    }
}

/// Lets VoiceOver reach the long-press menu's Delete All.
private struct DeleteAllAccessibilityAction: ViewModifier {
    let deleteAll: (@MainActor () -> Void)?

    func body(content: Content) -> some View {
        if let deleteAll {
            content.accessibilityAction(named: Text(l("bookmarks.delete-all")), deleteAll)
        } else {
            content
        }
    }
}

#Preview("Adaptive highlight colors") {
    let items: [HighlightColorsView.Item] = [
        .init(color: .green, count: 1204),
        .init(color: .yellow, count: 128),
        .init(color: .purple, count: 3),
        .init(color: .blue, count: 0),
        .init(color: .pink, count: 0),
    ]
    ScrollView([.horizontal, .vertical]) {
        VStack(alignment: .leading) {
            ForEach([320.0, 440, 900], id: \.self) { width in
                HighlightColorsView(items: items, selectColor: { _ in })
                    .frame(width: width)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
