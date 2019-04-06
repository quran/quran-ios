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
import GenericDataSources
import UIKit

protocol QariListPresentableListener: class {
    func onQariItemTapped(at index: Int)
    func onCancelButtonTapped()
}

class QariTableViewController: BaseTableViewController, QariListPresentable, QariListViewControllable {

    override var screen: Analytics.Screen { return .reciterSelection }

    weak var listener: QariListPresentableListener?

    private let dataSource = QarisDataSource()

    private var selectedQariIndex: Int?

    init() {
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = nil
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.ds_register(cellNib: QariTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        tableView.ds_useDataSource(dataSource)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))

        let selectionHandler = BlockSelectionHandler<Qari, QariTableViewCell>()
        selectionHandler.didSelectBlock = { [weak self] _, _, indexPath in
            self?.listener?.onQariItemTapped(at: indexPath.item)
        }
        dataSource.setSelectionHandler(selectionHandler)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedQariIndex = selectedQariIndex {
            selectItem(at: selectedQariIndex)
        }
    }

    @objc
    private func cancelButtonTapped() {
        listener?.onCancelButtonTapped()
    }

    func setQaris(_ qaris: [Qari], selectedQariIndex: Int) {
        dataSource.items = qaris
        self.selectedQariIndex = selectedQariIndex
        tableView?.reloadData()
        selectItem(at: selectedQariIndex)
    }

    private func selectItem(at index: Int) {
        tableView?.ds_selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
    }
}
