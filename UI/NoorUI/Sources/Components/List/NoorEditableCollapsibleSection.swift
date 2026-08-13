//
//  NoorEditableCollapsibleSection.swift
//
//
//  Created by Ahmed Nabil on 2026-05-13.
//

import Localization
import SwiftUI
import UIx

public struct NoorEditableCollapsibleSection<Item: Identifiable, ListItem: View>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        isExpanded: Binding<Bool>,
        _ items: [Item],
        showsHeaderDeleteAction: Bool = false,
        headerDeleteAction: AsyncAction? = nil,
        @ViewBuilder listItem: @escaping (Item) -> ListItem,
        onDelete: ItemDeletionAction<Item>? = nil
    ) {
        self.title = title
        _isExpanded = isExpanded
        self.items = items
        self.showsHeaderDeleteAction = showsHeaderDeleteAction
        self.headerDeleteAction = headerDeleteAction
        self.listItem = listItem
        self.onDelete = onDelete
    }

    // MARK: Public

    public var body: some View {
        Section {
            if isExpanded {
                rows
            }
        } header: {
            header
        }
    }

    // MARK: Internal

    let title: String
    @Binding var isExpanded: Bool
    let items: [Item]
    let showsHeaderDeleteAction: Bool
    let headerDeleteAction: AsyncAction?
    let listItem: (Item) -> ListItem
    var onDelete: ItemDeletionAction<Item>?

    @State private var deletingItemIDs: Set<Item.ID> = []

    // MARK: Private

    private var header: some View {
        HStack {
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

            if showsHeaderDeleteAction, let headerDeleteAction {
                Button {
                    Task {
                        await headerDeleteAction()
                    }
                } label: {
                    Label(l("button.delete"), systemImage: "xmark")
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var rows: some View {
        ForEach(items) { item in
            listItem(item)
                .noorDeleteSwipeAction(isEnabled: onDelete != nil) {
                    delete(item)
                }
        }
        .onDelete(perform: onDelete.map { onDelete in
            { indexSet in
                let itemsToDelete = indexSet.map { items[$0] }
                for itemToDelete in itemsToDelete {
                    delete(itemToDelete, action: onDelete)
                }
            }
        })
    }

    private func delete(_ item: Item) {
        guard let onDelete else {
            return
        }
        delete(item, action: onDelete)
    }

    private func delete(_ item: Item, action: ItemDeletionAction<Item>) {
        guard deletingItemIDs.insert(item.id).inserted else {
            return
        }
        guard let operation = action(item) else {
            deletingItemIDs.remove(item.id)
            return
        }

        Task { @MainActor in
            await operation()
            deletingItemIDs.remove(item.id)
        }
    }
}

extension NoorEditableCollapsibleSection {
    public func onDelete(action: ItemDeletionAction<Item>?) -> Self {
        var mutableSelf = self
        mutableSelf.onDelete = action
        return mutableSelf
    }
}
