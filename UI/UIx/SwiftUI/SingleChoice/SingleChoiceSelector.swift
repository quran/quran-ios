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
        configure: @escaping (Item, Item?) -> Content,
        onSelection: @escaping (Item) -> Void
    ) {
        self.sections = sections
        self.selected = selected
        self.configure = configure
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
        sections[section].items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as? Cell else {
            fatalError("Cell not of type \(Cell.self)")
        }
        let view = configure(sections[indexPath.section].items[indexPath.item], selected)
        cell.set(rootView: view, parentController: self)
        return cell
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.item]
        onSelection(item)
    }

    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    // MARK: Private

    private let sections: [SingleChoiceSection<Item>]
    private let selected: Item?
    private let onSelection: (Item) -> Void
    private let configure: (Item, Item?) -> Content

    private var cellReuseId: String {
        String(describing: Cell.self)
    }
}

// Adding default factory method
public func singleChoiceSelector<Item: Hashable>(
    style: UITableView.Style = .insetGrouped,
    sections: [SingleChoiceSection<Item>],
    selected: Item?,
    itemText: @escaping (Item) -> String,
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

    public init(sections: [SingleChoiceSection<Item>], selected: Binding<Item?>, itemText: @escaping (Item) -> String) {
        self.sections = sections
        _selected = selected
        self.itemText = itemText
    }

    // MARK: Public

    public var body: some View {
        PreferredContentSizeMatchesScrollView {
            List {
                ForEach(sections, id: \.header) { section in
                    if let header = section.header {
                        Section(header: Text(header)) {
                            itemsView(section.items)
                        }
                    } else {
                        itemsView(section.items)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: Private

    private let sections: [SingleChoiceSection<Item>]
    @Binding private var selected: Item?
    private let itemText: (Item) -> String

    private func itemsView(_ items: [Item]) -> some View {
        ForEach(items, id: \.self) { item in
            Button {
                selected = item
            } label: {
                SingleChoiceRow(text: itemText(item), selected: item == selected)
            }
        }
    }
}
