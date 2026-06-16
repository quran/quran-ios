//
//  SegmentedChoicesPicker.swift
//
//
//  Created by Mohamed Afifi on 2026-06-15.
//

import SwiftUI

public struct SegmentedChoicesPicker<Item: Hashable>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        items: [Item],
        selection: Binding<Item>,
        label: @escaping (Item) -> String
    ) {
        self.title = title
        self.items = items
        _selection = selection
        self.label = label
    }

    // MARK: Public

    public var body: some View {
        Picker(title, selection: $selection) {
            ForEach(items, id: \.self) { item in
                Text(label(item)).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Private

    private let title: String
    private let items: [Item]
    @Binding private var selection: Item
    private let label: (Item) -> String
}
