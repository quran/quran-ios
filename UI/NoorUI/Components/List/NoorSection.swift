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

    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        if let title {
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
    let content: Content
}

public struct NoorSection<Item: Identifiable, ListItem: View>: View {
    // MARK: Lifecycle

    public init(
        title: String? = nil,
        _ items: [Item],
        @ViewBuilder listItem: @escaping (Item) -> ListItem,
        onDelete: AsyncItemAction<Item>? = nil,
        onMove: ((IndexSet, Int) -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.listItem = listItem
        self.onDelete = onDelete
        self.onMove = onMove
    }

    // MARK: Public

    public var body: some View {
        if !items.isEmpty {
            NoorBasicSection(title: title) {
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
        }
    }

    // MARK: Internal

    let title: String?
    let items: [Item]
    let listItem: (Item) -> ListItem
    var onDelete: AsyncItemAction<Item>?
    var onMove: ((IndexSet, Int) -> Void)?
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
