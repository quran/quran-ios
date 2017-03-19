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

    private let dataSource = QarisDataSource(reuseIdentifier: cellReuseId)

    var selectedIndex: Int {
        didSet {
            onSelectedIndexChanged?(selectedIndex)
        }
    }

    var onSelectedIndexChanged: ((Int) -> Void)?

    init(style: UITableViewStyle, qaris: [Qari], selectedQariIndex: Int) {
        selectedIndex = selectedQariIndex
        super.init(style: style)
        setUp()
        dataSource.items = qaris

    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    fileprivate func setUp() {
        let selectionHandler = BlockSelectionHandler<Qari, QariTableViewCell>()
        selectionHandler.didSelectBlock = { [weak self] _, _, indexPath in
            self?.selectedIndex = indexPath.item
            self?.dismiss(animated: true, completion: nil)
        }
        dataSource.setSelectionHandler(selectionHandler)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = nil

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.register(UINib(nibName: "QariTableViewCell", bundle: nil), forCellReuseIdentifier: cellReuseId)

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        tableView.ds_useDataSource(dataSource)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissViewController))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.ds_selectItem(at: IndexPath(item: selectedIndex, section: 0), animated: false, scrollPosition: [])
    }

    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
