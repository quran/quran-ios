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

class BaseTableBasedViewController: BaseViewController, ScrollableToTop {

    weak var tableView: UITableView! // swiftlint:disable:this implicitly_unwrapped_optional
    weak var statusView: UIView?

    var clearsSelectionOnViewWillAppear: Bool = true

    lazy var refreshControl: UIRefreshControl = {
        return UIRefreshControl()
    }()

    override func loadView() {
        view = UIView()

        let tableView = UITableView()
        view.addAutoLayoutSubview(tableView)
        view.pinParentAllDirections(tableView)

        let statusView = UIView()
        statusView.backgroundColor = UIColor.appIdentity()
        view.addAutoLayoutSubview(statusView)
        view.pinParentHorizontal(statusView)
        view.addParentTopConstraint(statusView)
        statusView.addHeightConstraint(20)

        self.tableView = tableView
        self.statusView = statusView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if clearsSelectionOnViewWillAppear {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: animated)
            }
        }
    }

    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        let isCompact = newCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact))
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.statusView?.alpha = isCompact ? 0 : 1
            }, completion: nil)
    }

    func scrollToTop() {
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: true)
    }
}
