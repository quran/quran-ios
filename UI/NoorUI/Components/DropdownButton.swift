//
//  DropdownButton.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import SwiftUI

public struct DropdownButton<Item: Hashable, Content: View>: View {
    private let items: [Item]
    @Binding private var selectedItem: Item
    private let content: (Item) -> Content

    @ScaledMetric private var horizontalPadding = 12.0
    @ScaledMetric private var verticalPadding = 6.0
    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius

    public init(items: [Item], selectedItem: Binding<Item>, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        _selectedItem = selectedItem
        self.content = content
    }

    public var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button {
                    selectedItem = item
                } label: {
                    content(item)
                }
            }
        } label: {
            VStack {
                HStack {
                    content(selectedItem)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.systemGray)
            )
            .foregroundStyle(Color.label)
        }
    }
}
