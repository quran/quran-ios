//
//  QariTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

private let cellReuseId = "cell"

class QariTableViewController: UITableViewController {

    let dataSource = QarisDataSource(reuseIdentifier: cellReuseId)

    var selectedIndex: Int = 0 {
        didSet {
            onSelectedIndexChanged?(selectedIndex)
        }
    }

    var onSelectedIndexChanged: (Int -> Void)?

    func setQaris(qaris: [Qari]) {
        dataSource.items = qaris
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        let selectionHandler = BlockSelectionHandler<Qari, QariTableViewCell>()
        selectionHandler.didSelectBlock = { [weak self] _, _, indexPath in
            self?.selectedIndex = indexPath.item
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        dataSource.setSelectionHandler(selectionHandler)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = nil

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.registerNib(UINib(nibName: "QariTableViewCell", bundle: nil), forCellReuseIdentifier: cellReuseId)

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        tableView.ds_useDataSource(dataSource)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(dismissViewController))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.ds_selectItemAtIndexPath(NSIndexPath(forItem: selectedIndex, inSection: 0), animated: false, scrollPosition: .None)
    }

    func dismissViewController() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
