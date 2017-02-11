//
//  BaseTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class BaseTableViewController: UIViewController {

    weak var tableView: UITableView!
    weak var statusView: UIView?

    var clearsSelectionOnViewWillAppear: Bool = true

    override func loadView() {
        super.loadView()

        let tableView = UITableView()
        view.addAutoLayoutSubview(tableView)
        _ = view.pinParentAllDirections(tableView)

        let statusView = UIView()
        statusView.backgroundColor = UIColor.appIdentity()
        view.addAutoLayoutSubview(statusView)
        _ = view.pinParentHorizontal(statusView)
        _ = view.addParentTopConstraint(statusView)
        _ = statusView.addHeightConstraint(20)

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
}
