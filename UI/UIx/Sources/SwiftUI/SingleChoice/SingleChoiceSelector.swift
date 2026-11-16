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

    /// - Parameter showsBackground: Pass `false` to show the list on its container's background,
    ///   such as a popover's material. iOS 15 keeps the list background.
    public init(
        sections: [SingleChoiceSection<Item>],
        selected: Binding<Item?>,
        showsBackground: Bool = true,
        itemText: @escaping (Item) -> String
    ) {
        self.sections = sections
        _selected = selected
        self.showsBackground = showsBackground
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
            .scrollContentBackgroundHidden(!showsBackground)
        }
    }

    // MARK: Private

    private let sections: [SingleChoiceSection<Item>]
    @Binding private var selected: Item?
    private let showsBackground: Bool
    private let itemText: (Item) -> String

    private func itemsView(_ items: [Item]) -> some View {
        ForEach(items, id: \.self) { item in
            Button {
                selected = item
            } label: {
                SingleChoiceRow(text: itemText(item), selected: item == selected)
            }
            .listRowBackground(showsBackground ? nil : Color.clear)
        }
    }
}

private extension View {
    @ViewBuilder
    func scrollContentBackgroundHidden(_ hidden: Bool) -> some View {
        if #available(iOS 16.0, *) {
            scrollContentBackground(hidden ? .hidden : .automatic)
        } else {
            self
        }
    }
}
