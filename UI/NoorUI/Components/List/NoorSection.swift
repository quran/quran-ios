//
//  NoorSection.swift
//
//
//  Created by Mohamed Afifi on 2023-07-04.
//

import Localization
import SwiftUI
import UIx

public struct NoorSectionHeaderAction: Identifiable {
    // MARK: Lifecycle

    public init(image: NoorSystemImage, tintColor: Color? = nil, action: @escaping AsyncAction) {
        self.image = image
        self.tintColor = tintColor
        self.action = action
    }

    // MARK: Public

    public let id = UUID()
    public let image: NoorSystemImage
    public let tintColor: Color?
    public let action: AsyncAction
}

public struct NoorBasicSection<Content: View>: View {
    // MARK: Lifecycle

    public init(
        title: String? = nil,
        footer: String? = nil,
        isExpanded: Binding<Bool>? = nil,
        headerDeleteAction: AsyncAction? = nil,
        headerActions: [NoorSectionHeaderAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.isExpanded = isExpanded
        self.headerDeleteAction = headerDeleteAction
        self.headerActions = headerActions
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        if let isExpanded, #available(iOS 17.0, *) {
            Section(isExpanded: isExpanded) {
                content
            } header: {
                collapsibleHeader(isExpanded: isExpanded)
            }
        } else if let footer {
            if let title {
                Section {
                    content
                } header: {
                    Text(title)
                } footer: {
                    Text(footer)
                }
            } else {
                Section {
                    content
                } footer: {
                    Text(footer)
                }
            }
        } else if let title {
            Section {
                content
            } header: {
                Text(title)
            }
        } else {
            Section {
                content
            }
        }
    }

    // MARK: Internal

    let title: String?
    let footer: String?
    let isExpanded: Binding<Bool>?
    let headerDeleteAction: AsyncAction?
    let headerActions: [NoorSectionHeaderAction]
    let content: Content

    // MARK: Private

    @ViewBuilder
    private func collapsibleHeader(isExpanded: Binding<Bool>) -> some View {
        HStack {
            HStack {
                if let title {
                    Text(title)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.wrappedValue.toggle()
                }
            }
            ForEach(headerActions) { headerAction in
                Button {
                    Task {
                        await headerAction.action()
                    }
                } label: {
                    headerAction.image.image
                        .foregroundStyle(headerAction.tintColor ?? Color.accentColor)
                }
                .buttonStyle(.borderless)
            }
            Image(systemName: "chevron.down")
                .font(.footnote.weight(.semibold))
                .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                .onTapGesture {
                    withAnimation {
                        isExpanded.wrappedValue.toggle()
                    }
                }
        }
        .accessibilityLabel(title ?? "")
        .accessibilityHint(isExpanded.wrappedValue ? "Collapse section" : "Expand section")
        .swipeActions {
            if let headerDeleteAction {
                Button(role: .destructive) {
                    Task {
                        await headerDeleteAction()
                    }
                } label: {
                    Label(l("button.delete"), systemImage: "trash")
                }
            }
        }
    }
}

public struct SelfIdentifiable<T: Hashable>: Identifiable {
    // MARK: Lifecycle

    public init(value: T) {
        self.value = value
    }

    // MARK: Public

    public let value: T

    public var id: T { value }
}

public struct NoorSection<Item: Identifiable, ListItem: View>: View {
    // MARK: Lifecycle

    public init(
        title: String? = nil,
        isExpanded: Binding<Bool>? = nil,
        _ items: [Item],
        @ViewBuilder listItem: @escaping (Item) -> ListItem,
        headerDeleteAction: AsyncAction? = nil,
        headerActions: [NoorSectionHeaderAction] = [],
        onDelete: AsyncItemAction<Item>? = nil,
        onMove: ((IndexSet, Int) -> Void)? = nil
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.items = items
        self.listItem = listItem
        self.headerDeleteAction = headerDeleteAction
        self.headerActions = headerActions
        self.onDelete = onDelete
        self.onMove = onMove
    }

    // MARK: Public

    public var body: some View {
        if !items.isEmpty || title != nil {
            NoorBasicSection(
                title: title,
                isExpanded: isExpanded,
                headerDeleteAction: headerDeleteAction,
                headerActions: headerActions
            ) {
                rows
            }
        }
    }

    // MARK: Internal

    let title: String?
    let isExpanded: Binding<Bool>?
    let items: [Item]
    let listItem: (Item) -> ListItem
    var headerDeleteAction: AsyncAction?
    var headerActions: [NoorSectionHeaderAction]
    var onDelete: AsyncItemAction<Item>?
    var onMove: ((IndexSet, Int) -> Void)?

    // MARK: Private

    @ViewBuilder
    private var rows: some View {
        ForEach(items) { item in
            listItem(item)
        }
        .onDelete(perform: onDelete.map { onDelete in
            { indexSet in
                Task {
                    let itemsToDelete = indexSet.map { items[$0] }
                    for itemToDelete in itemsToDelete {
                        await onDelete(itemToDelete)
                    }
                }
            }
        })
        .onMove(perform: onMove)
    }
}

extension NoorSection {
    public func headerActions(_ actions: [NoorSectionHeaderAction]) -> Self {
        var mutableSelf = self
        mutableSelf.headerActions = actions
        return mutableSelf
    }

    public func onHeaderDelete(action: AsyncAction?) -> Self {
        var mutableSelf = self
        mutableSelf.headerDeleteAction = action
        return mutableSelf
    }

    public func onDelete(action: AsyncItemAction<Item>?) -> Self {
        var mutableSelf = self
        mutableSelf.onDelete = action
        return mutableSelf
    }

    public func onMove(action: ((IndexSet, Int) -> Void)?) -> Self {
        var mutableSelf = self
        mutableSelf.onMove = action
        return mutableSelf
    }
}
