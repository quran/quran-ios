import QuranAnnotations
import SwiftUI
import UIx

@MainActor
public struct ColoredBookmarksView: View {
    public struct Item: Identifiable {
        public init(color: HighlightColor, count: Int) {
            self.color = color
            self.count = count
        }

        public let color: HighlightColor
        public let count: Int
        public var id: HighlightColor { color }
    }

    public init(items: [Item], selectColor: @escaping (HighlightColor) -> Void) {
        self.items = items
        self.selectColor = selectColor
    }

    private let items: [Item]
    private let selectColor: (HighlightColor) -> Void
    @State private var horizontalContentWidth: CGFloat = 0
    @State private var labelWidth: CGFloat = 0
    @ScaledMetric private var spacing = 8
    @ScaledMetric private var inset = 12
    @ScaledMetric private var iconSize = 24
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
                        Button { selectColor(item.color) } label: {
                            Group {
                                if horizontal {
                                    horizontalContent(item)
                                } else {
                                    VStack(spacing: spacing / 2) {
                                        icon(item, width: min(iconSize, contentWidth))
                                        count(item)
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
                        .buttonStyle(BackgroundHighlightingStyle())
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .accessibilityElement(children: .ignore)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(item.color.localizedName)
                        .accessibilityValue(item.count.formatted())
                        .accessibilityIdentifier("collections.color.\(item.color)")
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

    private func horizontalContent(_ item: Item) -> some View {
        HStack(spacing: spacing) {
            icon(item)
            Text(item.color.localizedName)
                .font(.body.weight(.semibold))
                .foregroundColor(.label)
                .lineLimit(1)
            Spacer(minLength: 0)
            count(item)
        }
    }

    private func icon(_ item: Item, width: CGFloat? = nil) -> some View {
        Image(systemName: "bookmark.fill")
            .resizable()
            .scaledToFit()
            .frame(width: width ?? iconSize, height: iconSize)
            .foregroundColor(item.color.color)
    }

    private func count(_ item: Item) -> some View {
        Text(item.count.formatted())
            .font(.body.weight(.semibold))
            // swiftformat:disable:next isEmpty
            .foregroundColor(item.count > 0 ? .label : .tertiaryLabel)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func label(_ item: Item) -> some View {
        Text(item.color.localizedName)
            .font(.caption)
            .foregroundColor(.secondaryLabel)
            .lineLimit(1)
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

#Preview("Adaptive colored bookmarks") {
    let items: [ColoredBookmarksView.Item] = [
        .init(color: .green, count: 10),
        .init(color: .purple, count: 3),
        .init(color: .blue, count: 0),
        .init(color: .red, count: 0),
        .init(color: .yellow, count: 0),
    ]
    ScrollView([.horizontal, .vertical]) {
        VStack(alignment: .leading) {
            ForEach([320.0, 440, 900], id: \.self) { width in
                ColoredBookmarksView(items: items, selectColor: { _ in })
                    .frame(width: width)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
