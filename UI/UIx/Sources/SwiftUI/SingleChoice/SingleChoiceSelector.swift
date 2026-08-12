//
//  SingleChoiceSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import SwiftUI
import UIKit

public struct SingleChoiceSection<Item: Equatable> {
    // MARK: Lifecycle

    public init(header: String? = nil, items: [Item]) {
        self.header = header
        self.items = items
    }

    // MARK: Internal

    let header: String?
    let items: [Item]
}

public class SingleChoiceSelector<Item: Equatable, Content: View>: UITableViewController {
    private typealias Cell = HostingTableViewCell<Content>

    // MARK: Lifecycle

    public init(
        style: UITableView.Style,
        sections: [SingleChoiceSection<Item>],
        selected: Item?,
        configure: (Item, Item?) -> Content,
        onSelection: @escaping (Item) -> Void
    ) {
        self.sections = sections.map { section in
            Section(
                header: section.header,
                rows: section.items.map { Row(item: $0, content: configure($0, selected)) }
            )
        }
        self.onSelection = onSelection
        super.init(style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = tableView.contentSize
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView?.register(Cell.self, forCellReuseIdentifier: cellReuseId)
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as? Cell else {
            fatalError("Cell not of type \(Cell.self)")
        }
        let view = sections[indexPath.section].rows[indexPath.item].content
        cell.set(rootView: view, parentController: self)
        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].rows[indexPath.item].item
        onSelection(item)
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    // MARK: Private

    private let sections: [Section]
    private let onSelection: (Item) -> Void

    private struct Section {
        let header: String?
        let rows: [Row]
    }

    private struct Row {
        let item: Item
        let content: Content
    }

    private var cellReuseId: String {
        String(describing: Cell.self)
    }
}

// Adding default factory method
public func singleChoiceSelector<Item: Hashable>(
    style: UITableView.Style = .insetGrouped,
    sections: [SingleChoiceSection<Item>],
    selected: Item?,
    itemText: (Item) -> String,
    onSelection: @escaping (Item) -> Void
) -> SingleChoiceSelector<Item, SingleChoiceRow> {
    SingleChoiceSelector(
        style: style,
        sections: sections,
        selected: selected,
        configure: { item, selected in
            SingleChoiceRow(text: itemText(item), selected: selected == item)
        },
        onSelection: onSelection
    )
}

public struct SingleChoiceSelectorView<Item: Hashable>: View {
    // MARK: Lifecycle

    public init(sections: [SingleChoiceSection<Item>], selected: Binding<Item?>, itemText: (Item) -> String) {
        self.sections = sections.enumerated().map { index, section in
            ChoiceSection(
                id: index,
                header: section.header,
                choices: section.items.map { Choice(item: $0, text: itemText($0)) }
            )
        }
        _selected = selected
    }

    // MARK: Public

    public var body: some View {
        let selected = $selected

        PreferredContentSizeMatchesScrollView {
            List {
                ForEach(sections) { section in
                    if let header = section.header {
                        Section(header: Text(header)) {
                            itemsView(section.choices, selected: selected)
                        }
                    } else {
                        itemsView(section.choices, selected: selected)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: Private

    private let sections: [ChoiceSection]
    @Binding private var selected: Item?

    private func itemsView(_ choices: [Choice], selected: Binding<Item?>) -> some View {
        ForEach(choices) { choice in
            Button {
                selected.wrappedValue = choice.item
            } label: {
                SingleChoiceRow(text: choice.text, selected: choice.item == selected.wrappedValue)
            }
        }
    }

    private struct ChoiceSection: Identifiable {
        let id: Int
        let header: String?
        let choices: [Choice]
    }

    private struct Choice: Identifiable {
        let item: Item
        let text: String

        var id: Item { item }
    }
}
