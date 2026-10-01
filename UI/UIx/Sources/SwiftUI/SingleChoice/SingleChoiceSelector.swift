//
//  SingleChoiceSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import SwiftUI

public struct SingleChoiceSection<Item: Equatable> {
    // MARK: Lifecycle

    public init(header: String? = nil, items: [Item]) {
        self.header = header
        self.items = items
    }

    // MARK: Internal

    let header: String?
    let items: [Item]
}

public struct SingleChoiceSelectorView<Item: Hashable>: View {
    // MARK: Lifecycle

    public init(sections: [SingleChoiceSection<Item>], selected: Binding<Item?>, itemText: @escaping (Item) -> String) {
        self.sections = sections
        _selected = selected
        self.itemText = itemText
    }

    // MARK: Public

    public var body: some View {
        PreferredContentSizeMatchesScrollView {
            List {
                ForEach(sections, id: \.header) { section in
                    if let header = section.header {
                        Section(header: Text(header)) {
                            itemsView(section.items)
                        }
                    } else {
                        itemsView(section.items)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: Private

    private let sections: [SingleChoiceSection<Item>]
    @Binding private var selected: Item?
    private let itemText: (Item) -> String

    private func itemsView(_ items: [Item]) -> some View {
        ForEach(items, id: \.self) { item in
            Button {
                selected = item
            } label: {
                SingleChoiceRow(text: itemText(item), selected: item == selected)
            }
        }
    }
}
