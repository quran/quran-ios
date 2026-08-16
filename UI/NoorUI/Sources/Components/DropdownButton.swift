//
//  DropdownButton.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import SwiftUI

public struct DropdownButton<Item: Hashable, Content: View>: View {
    private let choices: [Choice]
    @Binding private var selectedItem: Item

    @ScaledMetric private var horizontalPadding = 12.0
    @ScaledMetric private var verticalPadding = 6.0
    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius

    public init(items: [Item], selectedItem: Binding<Item>, @ViewBuilder content: (Item) -> Content) {
        choices = items.map { Choice(item: $0, content: content($0)) }
        _selectedItem = selectedItem
    }

    public var body: some View {
        let choices = choices
        let selectedItem = $selectedItem
        let selectedContent = choices.first { $0.item == selectedItem.wrappedValue }?.content
        let horizontalPadding = horizontalPadding
        let verticalPadding = verticalPadding
        let cornerRadius = cornerRadius

        Menu {
            ForEach(choices) { choice in
                Button {
                    selectedItem.wrappedValue = choice.item
                } label: {
                    choice.content
                }
            }
        } label: {
            VStack {
                HStack {
                    selectedContent
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

    private struct Choice: Identifiable {
        let item: Item
        let content: Content

        var id: Item { item }
    }
}
