//
//  QariTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
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
import GenericDataSources

class QariTableViewController: UITableViewController {

    private let dataSource = QarisDataSource()

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
        tableView.ds_register(cellNib: QariTableViewCell.self)

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
