//
//  TranslationsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/22/17.
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

import BatchDownloader
import Localization
import NoorUI
import QuranText
import TranslationService
import UIKit
import Utilities

class TranslationsViewController: BaseTableViewController, EditControllerDelegate,
    TranslationsListPresentable
{
    // MARK: Lifecycle

    init(showEditButton: Bool, interactor: TranslationsListInteractor) {
        self.interactor = interactor
        self.showEditButton = showEditButton
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
        editController.isEnabled = showEditButton
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let editController = EditController(usesRightBarButton: true)

    var translations: [Translation.ID: TranslationItem] {
        get { dataSource?.translations ?? [:] }
        set {
            dataSource?.translations = newValue
            editController.onEditableItemsUpdated()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if showEditButton {
            title = lAndroid("prefs_translations")
        } else {
            title = l("translationsSelectionTitle")
            navigationItem.prompt = l("translationsSelectionPrompt")
        }

        tableView.delegate = self
        tableView.estimatedSectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = true
        tableView.ds_register(cellNib: TranslationTableViewCell.self, in: .module)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)

        let dataSourceActions = TranslationsDataSource.Actions(
            cancelDownloading: { [weak self] item in
                Task {
                    await self?.interactor.cancelDownloading(item)
                }
            },
            startDownloading: { [weak self] item in
                Task {
                    await self?.interactor.startDownloading(item)
                }
            }
        )
        dataSource = TranslationsDataSource(tableView: tableView, actions: dataSourceActions)

        // editing
        dataSource?.ds.actions.canEditRow = { [weak self] in self?.canEditRow($0) ?? false }
        dataSource?.ds.actions.commitEditing = { [weak self] in self?.commitEditing($0, item: $1) }
        editController.configure(tableView: tableView, delegate: self, navigationItem: navigationItem)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor in
            await interactor.start()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        editController.endEditing(animated)
    }

    func showActivityIndicator() {
        refreshControl?.beginRefreshing()
    }

    func hideActivityIndicator() {
        refreshControl?.endRefreshing()
    }

    // MARK: - Editing

    func hasItemsToEdit() -> Bool {
        translations.contains { canEditRow($0.key) }
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        // call it in the next cycle to give isEditing a chance to change
        DispatchQueue.main.async {
            self.editController.onEditingStateChanged()
        }
    }

    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        editController.onEditingStateChanged()
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let id = dataSource?.ds.itemIdentifier(for: indexPath) {
            if let translation = translations[id] {
                return translation.isDownloaded ? indexPath : nil
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let id = dataSource?.ds.itemIdentifier(for: indexPath) {
            Task {
                await interactor.selectTranslation(id)
            }
        }
    }

    // MARK: Private

    private let interactor: TranslationsListInteractor

    private var dataSource: TranslationsDataSource?

    private let showEditButton: Bool

    @objc
    private func refreshData() {
        Task { @MainActor in
            await interactor.userRequestedRefresh()
        }
    }

    private func canEditRow(_ id: Translation.ID) -> Bool {
        translations[id]?.isDownloaded ?? false
    }

    private func commitEditing(_ editingStyle: UITableViewCell.EditingStyle, item: Translation.ID) {
        if editingStyle == .delete {
            Task {
                await interactor.deleteTranslation(item)
            }
        }
    }
}
