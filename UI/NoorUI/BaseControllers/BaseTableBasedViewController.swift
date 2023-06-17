//
//  BaseTableBasedViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/29/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import UIKit

open class BaseTableBasedViewController: BaseViewController {
    // MARK: Open

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if clearsSelectionOnViewWillAppear {
            if let indexPath = tableView?.indexPathForSelectedRow {
                tableView?.deselectRow(at: indexPath, animated: animated)
            }
        }
    }

    // MARK: Public

    public weak var tableView: UITableView! // swiftlint:disable:this implicitly_unwrapped_optional

    override public func loadView() {
        view = UIView()

        let tableView = UITableView()
        view.backgroundColor = .systemGroupedBackground
        tableView.tableFooterView = UIView()
        view.addAutoLayoutSubview(tableView)
        tableView.vc.edges()

        self.tableView = tableView
    }

    // MARK: Internal

    var clearsSelectionOnViewWillAppear: Bool = true

    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
}
