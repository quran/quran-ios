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
        label: (Item) -> String
    ) {
        self.title = title
        choices = items.map { Choice(item: $0, title: label($0)) }
        _selection = selection
    }

    // MARK: Public

    public var body: some View {
        Picker(title, selection: $selection) {
            ForEach(choices) { choice in
                Text(choice.title).tag(choice.item)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Private

    private let title: String
    private let choices: [Choice]
    @Binding private var selection: Item

    private struct Choice: Identifiable {
        let item: Item
        let title: String

        var id: Item { item }
    }
}
