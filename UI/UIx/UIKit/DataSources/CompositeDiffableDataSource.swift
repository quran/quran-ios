//
//  CompositeDiffableDataSource.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import SwiftUI
import UIKit

private protocol ReusableCell {
}

extension ReusableCell {
    /// Represents a default reuse id. It is the class name as string.
    /// Usually (99.99% of the times) we register the cell once. So a unique name would be the reuse id.
    public static var reuseId: String {
        String(describing: self)
    }

    /// Represents a default nib name. It is the class name as string.
    /// Usually (99.99% of the times) we name the nib as the class name.
    public static var nibName: String {
        String(describing: self)
    }
}

extension UITableViewCell: ReusableCell {
}

@available(iOS 13.0, *)
public class CompositeDiffableDataSource<Section: Hashable, Item: Hashable & Identifiable> {
    public typealias CellSelectionHandler = (IndexPath, Item) -> Void

    typealias CellConfigurator = (UITableViewCell, Item) -> Void

    private struct RegistryItem {
        let cell: UITableViewCell.Type
        let configure: CellConfigurator
        let onSelected: CellSelectionHandler?
    }

    // MARK: Lifecycle

    public init(tableView: UITableView, viewController: UIViewController) {
        self.tableView = tableView
        self.viewController = viewController
        ds = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            self?.provideCell(tableView: tableView, indexPath: indexPath, item: item)
        }

        _delegate.shouldHighlight = { [weak self] indexPath in
            self?.shouldHighlight(at: indexPath) ?? false
        }
        _delegate.selectRowAtIndexPath = { [weak self] indexPath in
            self?.selectRow(at: indexPath)
        }
    }

    // MARK: Public

    public var deselectAutomatically = false

    public var dataSource: UITableViewDiffableDataSource<Section, Item> {
        ds
    }

    public var delegate: UITableViewDelegate {
        _delegate
    }

    // MARK: - Registration

    public func registerViewForItemKind<Content: View>(
        _ kind: Item.ID,
        configure: @escaping (Item, HostingTableViewCell<Content>) -> Content,
        onSelected: CellSelectionHandler? = nil
    ) {
        registerClassForKind(
            kind,
            configure: { [weak viewController] (cell: HostingTableViewCell<Content>, item) in
                guard let viewController else {
                    return
                }
                let view = configure(item, cell)
                cell.set(rootView: view, parentController: viewController)
            },
            onSelected: onSelected
        )
    }

    public func registerClassForKind<Cell: UITableViewCell>(
        _ kind: Item.ID,
        configure: @escaping (Cell, Item) -> Void,
        onSelected: CellSelectionHandler? = nil
    ) {
        precondition(registry[kind] == nil, "Registering same item kind multiple times")
        tableView?.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        registry[kind] = RegistryItem(
            cell: Cell.self,
            configure: { cell, item in
                guard let typedCell = cell as? Cell else {
                    fatalError("Cannot cast cell \(cell) to type \(Cell.self)")
                }
                configure(typedCell, item)
            },
            onSelected: onSelected
        )
    }

    // MARK: Private

    private var ds: UITableViewDiffableDataSource<Section, Item>! // swiftlint:disable:this implicitly_unwrapped_optional

    private let _delegate = TableViewDelegate()

    private var registry: [Item.ID: RegistryItem] = [:]

    private weak var tableView: UITableView?
    private weak var viewController: UIViewController?

    // MARK: - Configuration

    private func provideCell(tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell {
        guard let registryItem = registry[item.id] else {
            fatalError("Unregistered item '\(item)'")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: registryItem.cell.reuseId, for: indexPath)
        registryItem.configure(cell, item)
        return cell
    }

    // MARK: - Selection

    private func registryItem(at indexPath: IndexPath) -> (item: Item, registryItem: RegistryItem)? {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            if let registryItem = registry[item.id] {
                return (item, registryItem)
            }
        }
        return nil
    }

    private func shouldHighlight(at indexPath: IndexPath) -> Bool {
        if let registryItem = registryItem(at: indexPath) {
            return registryItem.registryItem.onSelected != nil
        }
        return false
    }

    private func selectRow(at indexPath: IndexPath) {
        if deselectAutomatically {
            tableView?.deselectRow(at: indexPath, animated: true)
        }
        if let registryItem = registryItem(at: indexPath) {
            registryItem.registryItem.onSelected?(indexPath, registryItem.item)
        }
    }
}

private class TableViewDelegate: NSObject, UITableViewDelegate {
    var shouldHighlight: ((IndexPath) -> Bool)?
    var selectRowAtIndexPath: ((IndexPath) -> Void)?

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        shouldHighlight?(indexPath) ?? false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectRowAtIndexPath?(indexPath)
    }
}
