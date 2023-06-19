//
//  AudioDownloadsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import BatchDownloader
import Localization
import NoorUI
import QuranAudio
import QuranAudioKit
import UIKit
import Utilities

class AudioDownloadsViewController: BaseTableBasedViewController,
    AudioDownloadsPresentable, UITableViewDelegate, EditControllerDelegate
{
    // MARK: Lifecycle

    init(interactor: AudioDownloadsInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var downloads: [Reciter: AudioDownloadItem] {
        get { dataSource?.downloads ?? [:] }
        set {
            dataSource?.downloads = newValue
            editController.onEditableItemsUpdated()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("audio_manager")

        tableView.delegate = self
        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = false
        tableView.ds_register(cellNib: AudioDownloadTableViewCell.self, in: .module)

        let dataSourceActions = AudioDownloadsDataSource.Actions(
            cancelDownloading: { [weak self] item in
                Task {
                    await self?.interactor.cancelDownloading(item.reciter)
                }
            },
            startDownloading: { [weak self] item in
                Task {
                    await self?.interactor.startDownloading(item.reciter)
                }
            }
        )
        dataSource = AudioDownloadsDataSource(tableView: tableView, actions: dataSourceActions)

        // editing
        dataSource?.ds.actions.canEditRow = { [weak self] in self?.canEditRowAt($0) ?? false }
        dataSource?.ds.actions.commitEditing = { [weak self] in self?.commitEditing($0, item: $1) }
        editController.configure(tableView: tableView, delegate: self, navigationItem: navigationItem)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await interactor.start()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        editController.endEditing(animated)
    }

    func showActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = activityIndicator
    }

    func hideActivityIndicator() {
        navigationItem.titleView = nil
    }

    func hasItemsToEdit() -> Bool {
        downloads.values.contains { canEdit($0) }
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        // call it in the next cycle to give isEditing a chance to change
        DispatchQueue.main.async {
            self.editController.onEditingStateChanged()
        }
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        editController.onEditingStateChanged()
    }

    // MARK: Private

    private let interactor: AudioDownloadsInteractor

    private var dataSource: AudioDownloadsDataSource?

    private let editController = EditController(usesRightBarButton: true)

    // MARK: - Editing

    private func canEdit(_ item: AudioDownloadItem) -> Bool {
        guard let size = item.size else {
            return false
        }
        // nothing downloaded
        if size.downloadedSizeInBytes == 0 {
            return false
        }
        // cannot edit downloading items
        return item.downloading == .notDownloading
    }

    private func canEditRowAt(_ reciter: Reciter) -> Bool {
        let download = downloads[reciter]
        return download.map { canEdit($0) } ?? false
    }

    private func commitEditing(_ editingStyle: UITableViewCell.EditingStyle, item: Reciter) {
        if editingStyle == .delete {
            Task {
                await interactor.deleteReciterFiles(item)
            }
        }
    }
}
