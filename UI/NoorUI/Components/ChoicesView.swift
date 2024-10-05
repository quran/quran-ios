//
//  ChoicesView.swift
//
//
//  Created by Mohamed Afifi on 2024-09-29.
//

import SwiftUI

public struct ChoicesView<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let itemLabel: (Item) -> String

    public init(items: [Item], selection: Binding<Item>, itemLabel: @escaping (Item) -> String) {
        self.items = items
        _selection = selection
        self.itemLabel = itemLabel
    }

    public var body: some View {
        Picker("", selection: $selection) {
            ForEach(items, id: \.self) { item in
                Text(itemLabel(item))
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
