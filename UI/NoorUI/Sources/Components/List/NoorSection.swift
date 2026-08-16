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

    public init(
        title: String? = nil,
        footer: String? = nil,
        isExpanded: Binding<Bool>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.isExpanded = isExpanded
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        if let isExpanded, #available(iOS 17.0, *) {
            Section(isExpanded: isExpanded) {
                content
            } header: {
                collapsibleHeader(isExpanded: isExpanded)
            }
        } else if let footer {
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
    let isExpanded: Binding<Bool>?
    let content: Content

    // MARK: Private

    @ViewBuilder
    private func collapsibleHeader(isExpanded: Binding<Bool>) -> some View {
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
        @ViewBuilder listItem: (Item) -> ListItem,
        onDelete: ItemDeletionAction<Item>? = nil,
        onMove: ((IndexSet, Int) -> Void)? = nil
    ) {
        self.title = title
        self.isExpanded = isExpanded
        entries = items.map { Entry(item: $0, content: listItem($0)) }
        self.onDelete = onDelete
        self.onMove = onMove
    }

    // MARK: Public

    public var body: some View {
        if !entries.isEmpty {
            NoorBasicSection(title: title, isExpanded: isExpanded) {
                rows
            }
        }
    }

    // MARK: Internal

    let title: String?
    let isExpanded: Binding<Bool>?
    let entries: [Entry]
    var onDelete: ItemDeletionAction<Item>?
    var onMove: ((IndexSet, Int) -> Void)?

    @State private var deletingItemIDs: Set<Item.ID> = []

    // MARK: Private

    @ViewBuilder
    private var rows: some View {
        ForEach(entries) { entry in
            entry.content
        }
        .onDelete(perform: deleteAction)
        .onMove(perform: onMove)
    }

    private var deleteAction: ((IndexSet) -> Void)? {
        onDelete.map { _ in
            { indexSet in
                let itemsToDelete = indexSet.map { entries[$0].item }
                for itemToDelete in itemsToDelete {
                    delete(itemToDelete)
                }
            }
        }
    }

    private func delete(_ item: Item) {
        guard deletingItemIDs.insert(item.id).inserted else {
            return
        }
        guard let operation = onDelete?(item) else {
            deletingItemIDs.remove(item.id)
            return
        }

        Task { @MainActor in
            await operation()
            deletingItemIDs.remove(item.id)
        }
    }

    struct Entry: Identifiable {
        let item: Item
        let content: ListItem

        var id: Item.ID { item.id }
    }
}

extension NoorSection {
    public func onDelete(action: ItemDeletionAction<Item>?) -> Self {
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
