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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if clearsSelectionOnViewWillAppear {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRowAtIndexPath(indexPath, animated: animated)
            }
        }
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection,
                                                  withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        let isCompact = newCollection.containsTraitsInCollection(UITraitCollection(verticalSizeClass: .Compact))
        coordinator.animateAlongsideTransition({ [weak self] _ in
            self?.statusView?.alpha = isCompact ? 0 : 1
            }, completion: nil)
    }
}
