//
//  NoorCollapsibleSection.swift
//
//
//  Created by QuranEngine on 2026.
//

import SwiftUI

public struct NoorCollapsibleSection<Item: Identifiable, ListItem: View>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        isExpanded: Binding<Bool>,
        _ items: [Item],
        @ViewBuilder listItem: @escaping (Item) -> ListItem
    ) {
        self.title = title
        _isExpanded = isExpanded
        self.items = items
        self.listItem = listItem
    }

    // MARK: Public

    public var body: some View {
        if !items.isEmpty {
            Section {
                if isExpanded {
                    ForEach(items) { item in
                        listItem(item)
                    }
                }
            } header: {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(title)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")
            }
        }
    }

    // MARK: Internal

    let title: String
    let items: [Item]
    let listItem: (Item) -> ListItem

    // MARK: Private

    @Binding private var isExpanded: Bool
}
