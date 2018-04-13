//
//  SettingsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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

class SettingsViewController: BaseTableBasedViewController {

    private let dataSource = SettingsDataSource()
    private let creators: SettingsCreators

    override var screen: Analytics.Screen { return .settings }

    init(creators: SettingsCreators) {
        self.creators = creators
        super.init(nibName: nil, bundle: nil)

        let selection = BlockSelectionHandler<Setting, UITableViewCell>()
        selection.didSelectBlock = { [weak self] ds, _, indexPath in
            guard let `self` = self else { return }
            let item = ds.item(at: indexPath)
            item.onSelection(self)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        dataSource.setSelectionHandler(selection)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func loadView() {
        let tableView = UITableView(frame: .zero, style: .grouped)
        view = tableView
        self.tableView = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("menu_settings", tableName: "Android", comment: "")

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(cellClass: UITableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        dataSource.items = creators.createSettingsItems()
    }
}
