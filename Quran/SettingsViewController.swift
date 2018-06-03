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
import MessageUI
import UIKit

class SettingsViewController: BaseTableBasedViewController {

    private let dataSource = CompositeDataSource(sectionType: .single)
    private let creators: SettingsCreators

    override var screen: Analytics.Screen { return .settings }

    init(creators: SettingsCreators) {
        self.creators = creators
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("menu_settings")

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        let selection = BlockSelectionHandler<Setting, SettingTableViewCell>()
        selection.didSelectBlock = { [weak self] ds, _, indexPath in
            guard let `self` = self else { return }
            let item = ds.item(at: indexPath)
            item.onSelection?(self)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }

        let items = creators.createSettingsItems()
        for (index, item) in items.enumerated() {
            if item is EmptySetting {
                let itemDS = EmptyDataSource()
                itemDS.itemHeight = 35
                itemDS.items = [()]
                dataSource.add(itemDS)
            } else {
                let itemDS = SettingsDataSource()
                itemDS.itemHeight = 51
                itemDS.zeroInset = index == items.count - 1 || items[index + 1] is EmptySetting
                itemDS.items = [item]
                itemDS.setSelectionHandler(selection)
                dataSource.add(itemDS)
            }
        }

        tableView.ds_register(cellClass: SettingTableViewCell.self)
        tableView.ds_register(cellClass: EmptyTableViewCell.self)
        tableView.ds_useDataSource(dataSource)
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
