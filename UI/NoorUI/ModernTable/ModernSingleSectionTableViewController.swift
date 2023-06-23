//
//  ModernSingleSectionTableViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/3/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIKit
import UIx

public struct ModernSingleSectionTableListener<Item> {
    // MARK: Lifecycle

    public init(viewDidLoad: @escaping () -> Void, viewWillAppear: @escaping () -> Void, selectItem: @escaping (Item) -> Void, deleteItem: @Sendable @escaping (Item) async -> Void) {
        self.viewDidLoad = viewDidLoad
        self.viewWillAppear = viewWillAppear
        self.selectItem = selectItem
        self.deleteItem = deleteItem
    }

    // MARK: Internal

    let viewDidLoad: () -> Void
    let viewWillAppear: () -> Void
    let selectItem: (Item) -> Void
    let deleteItem: @Sendable (Item) async -> Void
}

open class ModernSingleSectionTableViewController<ItemType, CellType>: ModernTableViewController
    where ItemType: Equatable, CellType: View
{
    // MARK: Lifecycle

    public init(dataSource: ModernEditableBasicDataSource<ItemType, CellType>, noDataView: @escaping () -> NoDataView) {
        self.dataSource = dataSource
        self.noDataView = noDataView
        super.init(dataSource: dataSource)
    }

    // MARK: Open

    override open func viewDidLoad() {
        configureDataSource()

        tableView.estimatedRowHeight = 70
        tableView.ds_register(cellClass: HostingTableViewCell<CellType>.self)

        super.viewDidLoad()
        listener?.viewDidLoad()
    }

    // MARK: Public

    public var listener: ModernSingleSectionTableListener<ItemType>?

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener?.viewWillAppear()
    }

    public func setItems(_ items: [ItemType]) {
        dataSource.items = items
    }

    // MARK: Private

    private let dataSource: ModernEditableBasicDataSource<ItemType, CellType>

    // MARK: - NO Data View

    private let noDataView: () -> NoDataView

    private var noDataViewController: UIHostingController<NoDataView>? {
        didSet {
            oldValue.map { removeChild($0) }
            noDataViewController.map { addFullScreenChild($0) }
            tableView.isHidden = noDataViewController != nil
        }
    }

    private func configureDataSource() {
        dataSource.setDidSelect { [weak self] ds, _, index in
            let item = ds.item(at: index)
            self?.listener?.selectItem(item)
        }
        dataSource.deleteItem = { [weak self] item, _ in
            guard let self else { return }
            Task {
                await self.listener?.deleteItem(item)
            }
        }
        dataSource.onItemsUpdated = { [weak self] _ in
            self?.showNoDataViewIfNeeded()
        }
    }

    private func showNoDataViewIfNeeded() {
        if dataSource.items.isEmpty {
            let rootView = noDataView()
            noDataViewController = UIHostingController(rootView: rootView)
            noDataViewController?.view.backgroundColor = nil
        } else {
            noDataViewController = nil
        }
    }
}
