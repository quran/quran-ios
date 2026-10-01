//
//  NoorExpandableRowHeader.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import SwiftUI

/// A list row that shows its current value and expands an inline editor, such as a wheel,
/// in the rows beneath it. While expanded, the value and chevron take the app tint.
public struct NoorExpandableRowHeader<Value: View>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        image: NoorSystemImage? = nil,
        isExpanded: Bool,
        action: @escaping @MainActor () -> Void,
        @ViewBuilder value: () -> Value
    ) {
        self.title = title
        self.image = image
        self.isExpanded = isExpanded
        self.action = action
        self.value = value()
    }

    // MARK: Public

    public var body: some View {
        Button(action: action) {
            NoorValueRowLabel(title: title, image: image) {
                HStack {
                    value
                        .foregroundStyle(isExpanded ? Color.accentColor : .secondary)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(isExpanded ? Color.accentColor : Color(.tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private let title: String
    private let image: NoorSystemImage?
    private let isExpanded: Bool
    private let action: @MainActor () -> Void
    private let value: Value
}

#Preview {
    struct Container: View {
        @State var isExpanded = false

        var body: some View {
            NoorList {
                NoorBasicSection {
                    NoorExpandableRowHeader(
                        title: "From",
                        image: .rangeStart,
                        isExpanded: isExpanded,
                        action: { isExpanded.toggle() }
                    ) {
                        Text("Al-Fatihah, Ayah 1")
                    }
                    if isExpanded {
                        Text("Inline editor")
                    }
                }
            }
            .noorListIconColumn()
        }
    }
    return Container()
}
