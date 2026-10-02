//
//  NoorMenuRow.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import SwiftUI
import UIx

/// A list row that shows its current value and opens a menu to pick another.
///
/// Each item is a toggle, so the menu checks the selected item natively. Tapping the
/// checked item again does nothing.
public struct NoorMenuRow<Item: Hashable, ItemLabel: View>: View {
    // MARK: Lifecycle

    /// A menu row whose value may be none of its items, such as "Custom".
    /// A `nil` `selectedItem` checks no item.
    public init(
        title: String,
        image: NoorSystemImage? = nil,
        items: [Item],
        selectedItem: Item?,
        value: String,
        onSelect: @escaping (Item) -> Void,
        @ViewBuilder itemLabel: @escaping (Item) -> ItemLabel
    ) {
        self.title = title
        self.image = image
        self.items = items
        self.selectedItem = selectedItem
        self.value = value
        self.onSelect = onSelect
        self.itemLabel = itemLabel
    }

    public init(
        title: String,
        image: NoorSystemImage? = nil,
        items: [Item],
        selection: Binding<Item>,
        value: String,
        @ViewBuilder itemLabel: @escaping (Item) -> ItemLabel
    ) {
        self.init(
            title: title,
            image: image,
            items: items,
            selectedItem: selection.wrappedValue,
            value: value,
            onSelect: { selection.wrappedValue = $0 },
            itemLabel: itemLabel
        )
    }

    // MARK: Public

    public var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Toggle(isOn: isSelected(item)) {
                    itemLabel(item)
                }
            }
        } label: {
            NoorValueRowLabel(title: title, image: image) {
                HStack {
                    Text(value)
                        .foregroundColor(.secondaryLabel)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.tertiaryLabel)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    // MARK: Private

    private let title: String
    private let image: NoorSystemImage?
    private let items: [Item]
    private let selectedItem: Item?
    private let value: String
    private let onSelect: (Item) -> Void
    private let itemLabel: (Item) -> ItemLabel

    private func isSelected(_ item: Item) -> Binding<Bool> {
        Binding(
            get: { item == selectedItem },
            set: { isOn in
                // Unchecking the selected item would leave nothing selected; ignore it.
                if isOn {
                    onSelect(item)
                }
            }
        )
    }
}

extension NoorMenuRow where ItemLabel == Text {
    /// A menu row whose items and value are plain text.
    public init(
        title: String,
        image: NoorSystemImage? = nil,
        items: [Item],
        selection: Binding<Item>,
        label: @escaping (Item) -> String
    ) {
        self.init(
            title: title,
            image: image,
            items: items,
            selection: selection,
            value: label(selection.wrappedValue)
        ) { item in
            Text(label(item))
        }
    }
}

#Preview {
    struct Container: View {
        @State var rate: Float = 1
        @State var end: String? = nil

        var body: some View {
            NoorList {
                NoorBasicSection {
                    NoorMenuRow(
                        title: "Playback Speed",
                        image: .playbackSpeed,
                        items: [0.5, 1, 1.5, 2],
                        selection: $rate,
                        label: { "\($0)×" }
                    )
                    NoorMenuRow(
                        title: "Play up to",
                        image: .playUpTo,
                        items: ["Page", "Juz'", "Surah", "Quran"],
                        selectedItem: end,
                        value: end ?? "Custom",
                        onSelect: { end = $0 }
                    ) { item in
                        Text(item)
                    }
                }
            }
            .noorListIconColumn()
        }
    }
    return Container()
}

#Preview("Accessibility size") {
    NoorList {
        NoorBasicSection {
            NoorMenuRow(
                title: "Pause Between Repetitions",
                image: .pauseDelay,
                items: ["Off", "1s", "2s"],
                selection: .constant("1s"),
                label: { $0 }
            )
        }
    }
    .noorListIconColumn()
    .dynamicTypeSize(.accessibility3)
}
