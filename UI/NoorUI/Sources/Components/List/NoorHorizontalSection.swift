import SwiftUI

/// A list section whose items appear as individually rounded, horizontally scrolling cards.
public struct NoorHorizontalSection<Item: Identifiable, Content: View>: View {
    public init(
        title: String,
        _ items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.content = content
    }

    public var body: some View {
        if !items.isEmpty {
            NoorBasicSection(title: title) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(items) { item in
                            content(item)
                                .background(Color.secondarySystemGroupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    private let title: String
    private let items: [Item]
    private let content: (Item) -> Content

    @ScaledMetric(relativeTo: .body) private var spacing = 10
    @ScaledMetric(relativeTo: .body) private var cornerRadius = 22
}

#Preview {
    NoorList {
        NoorHorizontalSection(title: "Recent pages", [1, 50, 100].map { SelfIdentifiable(value: $0) }) { item in
            Button {} label: {
                Label("Page \(item.value)", systemImage: "clock")
                    .padding()
            }
            .buttonStyle(.plain)
        }
    }
}
