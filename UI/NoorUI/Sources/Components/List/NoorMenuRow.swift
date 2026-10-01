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
/// A `nil` selection checks no item, so the row can show a value that isn't
/// one of the menu items, such as "Custom".
public struct NoorMenuRow<Item: Hashable, ItemLabel: View>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        image: NoorSystemImage,
        items: [Item],
        selection: Binding<Item?>,
        value: String,
        @ViewBuilder itemLabel: @escaping (Item) -> ItemLabel
    ) {
        self.title = title
        self.image = image
        self.items = items
        _selection = selection
        self.value = value
        self.itemLabel = itemLabel
    }

    public init(
        title: String,
        image: NoorSystemImage,
        items: [Item],
        selection: Binding<Item>,
        value: String,
        @ViewBuilder itemLabel: @escaping (Item) -> ItemLabel
    ) {
        self.init(
            title: title,
            image: image,
            items: items,
            selection: Binding<Item?>(
                get: { selection.wrappedValue },
                set: { newValue in
                    if let newValue {
                        selection.wrappedValue = newValue
                    }
                }
            ),
            value: value,
            itemLabel: itemLabel
        )
    }

    // MARK: Public

    public var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(items, id: \.self) { item in
                    itemLabel(item)
                        .tag(Optional(item))
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

    @Binding private var selection: Item?

    private let title: String
    private let image: NoorSystemImage
    private let items: [Item]
    private let value: String
    private let itemLabel: (Item) -> ItemLabel
}

extension NoorMenuRow where ItemLabel == Text {
    /// A menu row whose items and value are plain text.
    public init(
        title: String,
        image: NoorSystemImage,
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
                        selection: $end,
                        value: end ?? "Custom"
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
