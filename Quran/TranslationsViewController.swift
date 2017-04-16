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

import UIKit
import GenericDataSources

class TranslationsViewController: BaseTableBasedViewController, TranslationsDataSourceDelegate {

    override var screen: Analytics.Screen { return .translations }

    private let dataSource: TranslationsDataSource

    private let interactor: AnyInteractor<Void, [TranslationFull]>
    private let localTranslationsInteractor: AnyInteractor<Void, [TranslationFull]>

    private var activityIndicator: UIActivityIndicatorView? {
        return navigationItem.leftBarButtonItem?.customView as? UIActivityIndicatorView
    }

    init(interactor: AnyInteractor<Void, [TranslationFull]>,
         localTranslationsInteractor: AnyInteractor<Void, [TranslationFull]>,
         dataSource: TranslationsDataSource) {
        self.interactor = interactor
        self.localTranslationsInteractor = localTranslationsInteractor
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
        dataSource.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo22").withRenderingMode(.alwaysTemplate))

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = false
        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_register(cellNib: TranslationTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl)

        dataSource.downloadedDS.onItemsUpdated = { [weak self] _ in
            self?.onDownloadedItemsUpdated()
        }

        loadLocalData()

        dataSource.onEditingChanged = { [weak self] in
            self?.updateRightBarItem(animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator?.startAnimating()
        loadLocalData {
            self.refreshData()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.setEditing(false, animated: animated)
        updateRightBarItem(animated: animated)
    }

    func translationsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }

    @objc private func refreshData() {
        interactor.execute()
            .then(on: .main) { [weak self] translations -> Void in
                self?.dataSource.setItems(items: translations)
                self?.tableView.reloadData()
            }.catchToAlertView(viewController: self)
            .always(on: .main) { [weak self] in
                self?.refreshControl.endRefreshing()
                self?.activityIndicator?.stopAnimating()
        }
    }

    private func loadLocalData(completion: @escaping () -> Void = { }) {
        localTranslationsInteractor.execute()
            .then(on: .main) { [weak self] translations -> Void in
                self?.dataSource.setItems(items: translations)
                self?.tableView.reloadData()
            } .always {
                completion()
            }.catchToAlertView(viewController: self)
    }

    private func onDownloadedItemsUpdated() {
        guard !dataSource.downloadedDS.isSelectable else {
            return
        }

        if dataSource.downloadedDS.items.isEmpty {
            tableView.setEditing(false, animated: true)
        }

        updateRightBarItem(animated: true)
    }

    private func updateRightBarItem(animated: Bool) {
        let button: UIBarButtonItem?
        if dataSource.downloadedDS.items.isEmpty {
            button = nil
        } else if tableView.isEditing {
            button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDoneTapped))
        } else {
            button = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(onEditTapped))
        }
        if navigationItem.rightBarButtonItem?.action != button?.action {
            navigationItem.setRightBarButton(button, animated: animated)
        }
    }

    @objc private func onEditTapped() {
        tableView.setEditing(true, animated: true)
        updateRightBarItem(animated: true)
    }

    @objc private func onDoneTapped() {
        tableView.setEditing(false, animated: true)
        updateRightBarItem(animated: true)
    }
}
