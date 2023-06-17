//
//  ModernTableViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/3/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Foundation
import UIKit
import Utilities

open class ModernTableViewController: BaseTableBasedViewController {
    // MARK: Lifecycle

    public init(dataSource: ModernDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.ds_useDataSource(dataSource)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let editableDS = dataSource as? EditableDataSource {
            editableDS.endEditing(animated: animated)
        }
    }

    // MARK: Private

    private let dataSource: ModernDataSource

    private func configureDataSource() {
        dataSource.controller = self
        if let editableDS = dataSource as? EditableDataSource {
            editableDS.configureEditController(tableView, navigationItem: navigationItem)
        }
    }
}
