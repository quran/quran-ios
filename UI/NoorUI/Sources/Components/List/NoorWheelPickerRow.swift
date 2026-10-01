//
//  NoorWheelPickerRow.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import SwiftUI
import UIx

/// A list row that shows its current value and expands an inline wheel to pick another.
public struct NoorWheelPickerRow<Item: Hashable, ItemLabel: View>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        image: NoorSystemImage? = nil,
        items: [Item],
        selection: Binding<Item>,
        @ViewBuilder label: @escaping (Item) -> ItemLabel
    ) {
        self.title = title
        self.image = image
        self.items = items
        _selection = selection
        self.label = label
    }

    // MARK: Public

    public var body: some View {
        Group {
            NoorExpandableRowHeader(
                title: title,
                image: image,
                isExpanded: isExpanded,
                action: toggle
            ) {
                label(selection)
            }

            if isExpanded {
                Picker(title, selection: $selection) {
                    ForEach(items, id: \.self) { item in
                        label(item)
                            .tag(item)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: pickerHeight)
                .clipped()
            }
        }
    }

    // MARK: Private

    @Binding private var selection: Item
    @State private var isExpanded = false
    @ScaledMetric private var pickerHeight: CGFloat = 150

    private let title: String
    private let image: NoorSystemImage?
    private let items: [Item]
    private let label: (Item) -> ItemLabel

    private func toggle() {
        withAnimation(NoorAnimation.standard) {
            isExpanded.toggle()
        }
    }
}

#Preview {
    struct Container: View {
        @State var count = 1

        var body: some View {
            NoorList {
                NoorBasicSection {
                    NoorWheelPickerRow(
                        title: "Repeat Count",
                        image: .repeatVerse,
                        items: Array(1 ... 100),
                        selection: $count
                    ) { count in
                        Text("\(count)×")
                    }
                }
            }
            .noorListIconColumn()
        }
    }
    return Container()
}
