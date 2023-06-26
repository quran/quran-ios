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

import Localization
import MessageUI
import NoorUI
import SwiftUI
import UIKit
import UIx
import Utilities

class SettingsViewController: BaseViewController {
    // MARK: Lifecycle

    init(settings: [SettingSection]) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let settings: [SettingSection]
    var tableView: UITableView! // swiftlint:disable:this implicitly_unwrapped_optional

    override func loadView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createDataSource()
        populateItems()

        tableView.delegate = compositeDS?.delegate

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
    }

    // MARK: Private

    private var compositeDS: CompositeDiffableDataSource<SettingSection.Id, SettingBox>?

    private static func configureActionableCell(_ cell: SettingTableViewCell, setting: ActionableSetting) {
        cell.textLabel?.text = setting.name
        cell.imageView?.image = setting.image?.withRenderingMode(.alwaysTemplate)
        cell.accessoryType = .disclosureIndicator
    }

    private static func configureInfoCell(_ cell: Value1SettingTableViewCell, setting: InfoSetting) {
        cell.textLabel?.text = setting.name
        cell.detailTextLabel?.text = setting.details
        cell.accessoryType = .none
    }

    private func populateItems() {
        var snapshot = NSDiffableDataSourceSnapshot<SettingSection.Id, SettingBox>()
        snapshot.appendSections(settings.map(\.section))
        for section in settings {
            snapshot.appendItems(section.settings, toSection: section.section)
        }
        compositeDS?.dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func createDataSource() {
        compositeDS = CompositeDiffableDataSource(tableView: tableView, viewController: self)
        compositeDS?.deselectAutomatically = true
        registerViewFactories()
    }

    private func registerViewFactories() {
        for setting in Set(settings.flatMap(\.settings).map(\.id)) {
            switch setting {
            case .actionable:
                registerActionableSetting()
            case .actionableSubtitle:
                registerActionableSubtitleSetting()
            case .theme:
                registerTheme()
            case .info:
                registerInfo()
            }
        }
    }

    private func registerInfo() {
        compositeDS?.registerClassForKind(
            .info,
            configure: { (cell: Value1SettingTableViewCell, item) in
                let setting = item.data as! InfoSetting // swiftlint:disable:this force_cast
                Self.configureInfoCell(cell, setting: setting)
            },
            onSelected: nil
        )
    }

    private func registerTheme() {
        compositeDS?.registerViewForItemKind(.theme) { item, _ -> ViewModelContainer<ValueViewModel<Theme>, ThemeSelector> in
            let setting = item.data as! ThemeSetting // swiftlint:disable:this force_cast
            return ViewModelContainer(setting.theme, content: { ThemeSelector(theme: $0.value) })
        }
    }

    private func registerActionableSetting() {
        compositeDS?.registerClassForKind(
            .actionable,
            configure: { (cell: DefaultSettingTableViewCell, item) in
                let setting = item.data as! Setting // swiftlint:disable:this force_cast
                Self.configureActionableCell(cell, setting: setting)
            },
            onSelected: { [weak self] indexPath, item in
                self?.onIndexPathSelected(indexPath, item: item)
            }
        )
    }

    private func registerActionableSubtitleSetting() {
        compositeDS?.registerClassForKind(
            .actionableSubtitle,
            configure: { (cell: Value1SettingTableViewCell, item) in
                let setting = item.data as! SubtitleSetting // swiftlint:disable:this force_cast
                Self.configureActionableCell(cell, setting: setting)
                cell.bindDetailsTo(setting.subtitle)
            },
            onSelected: { [weak self] indexPath, item in
                self?.onIndexPathSelected(indexPath, item: item)
            }
        )
    }

    private func onIndexPathSelected(_ indexPath: IndexPath, item: SettingBox) {
        if let cell = tableView.cellForRow(at: indexPath) {
            let setting = item.data as! ActionableSetting // swiftlint:disable:this force_cast
            setting.action(cell)
        }
    }
}
