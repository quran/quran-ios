//
//  AudioDownloadsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
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
import GenericDataSources
import UIKit

protocol AudioDownloadsPresentableListener: class {
}

class AudioDownloadsViewController: BaseTableBasedViewController, AudioDownloadsDataSourceDelegate, EditControllerDelegate,
                    AudioDownloadsPresentable, AudioDownloadsViewControllable {

    weak var listener: AudioDownloadsPresentableListener?

    private let editController = EditController(usesRightBarButton: true)
    private let dataSource: AudioDownloadsDataSource
    private let retriever: DownloadableQariAudioRetrieverType

    override var screen: Analytics.Screen { return .audioDownloads }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    init(retriever: DownloadableQariAudioRetrieverType,
         downloader: DownloadManager,
         ayahsDownloader: AnyInteractor<AyahsAudioDownloadRequest, DownloadBatchResponse>,
         qariAudioDownloadRetriever: QariListToQariAudioDownloadRetrieverType,
         deletionInteractor: AnyInteractor<Qari, Void>) {
        self.retriever = retriever
        self.dataSource = AudioDownloadsDataSource(downloader: downloader,
                                                   ayahsDownloader: ayahsDownloader,
                                                   qariAudioDownloadRetriever: qariAudioDownloadRetriever,
                                                   deletionInteractor: deletionInteractor)
        super.init(nibName: nil, bundle: nil)
        dataSource.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("audio_manager")

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = false
        tableView.ds_register(cellNib: AudioDownloadTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        editController.configure(tableView: tableView, delegate: self, navigationItem: navigationItem)
        dataSource.onItemsUpdated = { [weak self] _ in
            self?.editController.onEditableItemsUpdated()
        }
        dataSource.onEditingChanged = { [weak self] in
            self?.editController.onStartSwipingToEdit()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showActivityIndicator()
        loadLocalData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        editController.endEditing(animated)
    }

    func audioDownloadsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }

    private func loadLocalData() {
        // empty the view for reloading
        dataSource.items = []
        tableView.reloadData()

        // get new data
        retriever.getDownloadableQariAudios()
            .done(on: .main) { [weak self] audios -> Void in
                self?.dataSource.items = audios.sorted { $0.audio.downloadedSizeInBytes > $1.audio.downloadedSizeInBytes }
                self?.tableView.reloadData()
            }.catchToAlertView(viewController: self)
            .finally(on: .main) {
                self.hideActivityIndicator()
            }
    }

    func hasItemsToEdit() -> Bool {
        var canEdit = false
        for item in dataSource.items {
            if item.audio.downloadedSizeInBytes != 0 && item.response == nil {
                canEdit = true
                break
            }
        }
        return canEdit
    }

    private func showActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        navigationItem.titleView = activityIndicator
    }

    private func hideActivityIndicator() {
        navigationItem.titleView = nil
    }
}
