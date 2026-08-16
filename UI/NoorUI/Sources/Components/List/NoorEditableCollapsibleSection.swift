//
//  NoorEditableCollapsibleSection.swift
//
//
//  Created by Ahmed Nabil on 2026-05-13.
//

import Localization
import SwiftUI
import UIx

public struct NoorEditableCollapsibleSection<Item: Identifiable, ListItem: View>: View {
    // MARK: Lifecycle

    public init(
        title: String,
        isExpanded: Binding<Bool>,
        _ items: [Item],
        showsHeaderDeleteAction: Bool = false,
        headerDeleteAction: AsyncAction? = nil,
        onDelete: ItemDeletionAction<Item>? = nil,
        @ViewBuilder listItem: @escaping (Item) -> ListItem
    ) {
        self.title = title
        _isExpanded = isExpanded
        self.showsHeaderDeleteAction = showsHeaderDeleteAction
        self.headerDeleteAction = headerDeleteAction
        rows = NoorListRows(items, onDelete: onDelete, row: listItem)
    }

    // MARK: Public

    public var body: some View {
        Section {
            if isExpanded {
                rows
            }
        } header: {
            header
        }
    }

    // MARK: Internal

    let title: String
    @Binding var isExpanded: Bool
    let showsHeaderDeleteAction: Bool
    let headerDeleteAction: AsyncAction?
    let rows: NoorListRows<Item, ListItem>

    // MARK: Private

    private var header: some View {
        HStack {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsHeaderDeleteAction, let headerDeleteAction {
                Button {
                    Task {
                        await headerDeleteAction()
                    }
                } label: {
                    Label(l("button.delete"), systemImage: "xmark")
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .accessibilityLabel(title)
    }
}
