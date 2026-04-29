//
//  NoorSection.swift
//
//
//  Created by Mohamed Afifi on 2023-07-04.
//

import SwiftUI
import UIx

public struct NoorBasicSection<Content: View>: View {
    // MARK: Lifecycle

    public init(title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        if let footer {
            if let title {
                Section {
                    content
                } header: {
                    Text(title)
                } footer: {
                    Text(footer)
                }
            } else {
                Section {
                    content
                } footer: {
                    Text(footer)
                }
            }
        } else if let title {
            Section {
                content
            } header: {
                Text(title)
            }
        } else {
            Section {
                content
            }
        }
    }

    // MARK: Internal

    let title: String?
    let footer: String?
    let content: Content
}

public struct SelfIdentifiable<T: Hashable>: Identifiable {
    // MARK: Lifecycle

    public init(value: T) {
        self.value = value
    }

    // MARK: Public

    public let value: T

    public var id: T { value }
}

public struct NoorSection<Item: Identifiable, ListItem: View>: View {
    // MARK: Lifecycle

    public init(
        title: String? = nil,
        isExpanded: Binding<Bool>? = nil,
        _ items: [Item],
        @ViewBuilder listItem: @escaping (Item) -> ListItem,
        onDelete: AsyncItemAction<Item>? = nil,
        onMove: ((IndexSet, Int) -> Void)? = nil
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.items = items
        self.listItem = listItem
        self.onDelete = onDelete
        self.onMove = onMove
    }

    // MARK: Public

    public var body: some View {
        if !items.isEmpty {
            if let isExpanded {
                collapsibleSection(isExpanded: isExpanded)
            } else {
                NoorBasicSection(title: title) {
                    rows
                }
            }
        }
    }

    // MARK: Internal

    let title: String?
    let isExpanded: Binding<Bool>?
    let items: [Item]
    let listItem: (Item) -> ListItem
    var onDelete: AsyncItemAction<Item>?
    var onMove: ((IndexSet, Int) -> Void)?

    // MARK: Private

    @ViewBuilder
    private var rows: some View {
        ForEach(items) { item in
            listItem(item)
        }
        .onDelete(perform: onDelete.map { onDelete in
            { indexSet in
                Task {
                    let itemsToDelete = indexSet.map { items[$0] }
                    for itemToDelete in itemsToDelete {
                        await onDelete(itemToDelete)
                    }
                }
            }
        })
        .onMove(perform: onMove)
    }

    @ViewBuilder
    private func collapsibleSection(isExpanded: Binding<Bool>) -> some View {
        Section {
            if isExpanded.wrappedValue {
                rows
            }
        } header: {
            Button {
                withAnimation {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    if let title {
                        Text(title)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title ?? "")
            .accessibilityHint(isExpanded.wrappedValue ? "Collapse section" : "Expand section")
        }
    }
}

extension NoorSection {
    public func onDelete(action: AsyncItemAction<Item>?) -> Self {
        var mutableSelf = self
        mutableSelf.onDelete = action
        return mutableSelf
    }

    public func onMove(action: ((IndexSet, Int) -> Void)?) -> Self {
        var mutableSelf = self
        mutableSelf.onMove = action
        return mutableSelf
    }
}
