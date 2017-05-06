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

class AudioDownloadsViewController: BaseTableBasedViewController, AudioDownloadsDataSourceDelegate {

    private let dataSource: AudioDownloadsDataSource

    private let retriever: AnyGetInteractor<[DownloadableQariAudio]>

    override var screen: Analytics.Screen { return .audioDownloads }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var activityIndicator: UIActivityIndicatorView? {
        return navigationItem.leftBarButtonItem?.customView as? UIActivityIndicatorView
    }

    init(retriever: AnyGetInteractor<[DownloadableQariAudio]>,
         downloader: DownloadManager,
         ayahsDownloader: AnyInteractor<AyahsAudioDownloadRequest, DownloadBatchResponse>,
         qariAudioDownloadRetriever: AnyInteractor<[Qari], [QariAudioDownload]>,
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
        tableView.ds_register(cellNib: AudioDownloadTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        dataSource.onItemsUpdated = { [weak self] _ in
            self?.onDownloadedItemsUpdated()
        }

        dataSource.onEditingChanged = { [weak self] in
            self?.updateRightBarItem(animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator?.startAnimating()
        loadLocalData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.setEditing(false, animated: animated)
        updateRightBarItem(animated: animated)
    }

    func audioDownloadsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }

    private func loadLocalData() {
        // empty the view for reloading
        dataSource.items = []
        tableView.reloadData()

        // get new data
        retriever.get()
            .then(on: .main) { [weak self] audios -> Void in
                self?.dataSource.items = audios.sorted { $0.audio.downloadedSizeInBytes > $1.audio.downloadedSizeInBytes }
                self?.tableView.reloadData()
            }.catchToAlertView(viewController: self)
            .always(on: .main) {
                self.activityIndicator?.stopAnimating()
            }
    }

    private func hasMoreItemsToEdit() -> Bool {
        var canEdit = false
        for item in dataSource.items {
            if item.audio.downloadedSizeInBytes != 0 && item.response == nil {
                canEdit = true
                break
            }
        }
        return canEdit
    }

    private func onDownloadedItemsUpdated() {
        if !hasMoreItemsToEdit() {
            tableView.setEditing(false, animated: true)
        }

        updateRightBarItem(animated: true)
    }

    private func updateRightBarItem(animated: Bool) {
        let button: UIBarButtonItem?
        if !hasMoreItemsToEdit() {
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

    @objc
    private func onEditTapped() {
        tableView.setEditing(true, animated: true)
        updateRightBarItem(animated: true)
    }

    @objc
    private func onDoneTapped() {
        tableView.setEditing(false, animated: true)
        updateRightBarItem(animated: true)
    }
}
