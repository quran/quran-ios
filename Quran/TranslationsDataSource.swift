//
//  TranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

protocol TranslationsDataSourceDelegate: class {
    func translationsDataSource(_ dataSource: TranslationsDataSource, errorOccurred error: Error)
}

class TranslationsDataSource: CompositeDataSource, TranslationsBasicDataSourceDelegate {

    weak var delegate: TranslationsDataSourceDelegate?

    private let downloader: DownloadManager

    private let downloadedDS: TranslationsBasicDataSource
    private let pendingDS: TranslationsBasicDataSource

    private var downloadingObservers: [Int: DownloadingObserver] = [:]

    public init(downloader: DownloadManager, headerReuseId: String) {
        self.downloader = downloader
        downloadedDS = TranslationsBasicDataSource(downloader: downloader, reuseIdentifier: TranslationTableViewCell.reuseId)
        pendingDS = TranslationsBasicDataSource(downloader: downloader, reuseIdentifier: TranslationTableViewCell.reuseId)
        super.init(sectionType: .multi)

        let headers = TranslationsHeaderSupplementaryViewCreator(identifier: headerReuseId)
        headers.setSectionedItems([
            NSLocalizedString("downloaded_translations", tableName: "Android", comment: ""),
            NSLocalizedString("available_translations", tableName: "Android", comment: "")
            ])

        set(headerCreator: headers)
        add(downloadedDS)
        add(pendingDS)

        downloadedDS.delegate = self
        pendingDS.delegate = self
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    sizeForSupplementaryViewOfKind kind: String,
                                    at indexPath: IndexPath) -> CGSize {
        if dataSource(at: indexPath.section).ds_numberOfItems(inSection: 0) == 0 {
            return .zero
        } else {
            return super.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
        }
    }

    func setItems(items: [TranslationFull]) {
        downloadingObservers.forEach { $1.stop() }
        downloadingObservers.removeAll()

        downloadedDS.items = items.filter { $0.downloaded }.sorted { $0.translation.displayName < $1.translation.displayName }
        pendingDS.items = items.filter { !$0.downloaded }.sorted { $0.translation.displayName < $1.translation.displayName }

        for item in pendingDS.items {
            if item.downloadResponse != nil {
                downloadingObservers[item.translation.id] = DownloadingObserver(translation: item, dataSource: self)
            }
        }
    }

    fileprivate func onDownloadProgressUpdated(progress: Float, for translation: TranslationFull) {
        guard let localIndexPath = pendingDS.indexPath(for: translation) else {
            CLog("Cannot updated progress for translation \(translation.translation.displayName)")
            return
        }
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: pendingDS)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.setDownloadState(progress.downloadState)
    }

    fileprivate func onDownloadCompleted(withError error: Error, for translation: TranslationFull) {
        guard let localIndexPath = pendingDS.indexPath(for: translation) else {
            CLog("Cannot updated progress for translation \(translation.translation.displayName)")
            return
        }

        delegate?.translationsDataSource(self, errorOccurred: error)
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: pendingDS)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.setDownloadState(.notDownloaded)

        // update the item to be not downloading
        let newItem = TranslationFull(translation: translation.translation, downloaded: false, downloadResponse: nil)
        var newItems = pendingDS.items
        newItems[localIndexPath.item] = newItem
        pendingDS.items = newItems
    }

    fileprivate func onDownloadCompleted(for translation: TranslationFull) {
        guard let localIndexPath = pendingDS.indexPath(for: translation) else {
            CLog("Cannot complete download for translation \(translation.translation.displayName)")
            return
        }
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: pendingDS)

        // remove old observer
        let observer = downloadingObservers.removeValue(forKey: translation.translation.id)
        observer?.stop()

        // update the cell
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.setDownloadState(.downloaded)

        // remove from old location
        pendingDS.items.remove(at: localIndexPath.item)
        let newItem = TranslationFull(translation: translation.translation, downloaded: true, downloadResponse: nil)

        // add in new location
        var downloadedItems = downloadedDS.items
        downloadedItems.append(newItem)
        downloadedItems.sort { $0.translation.displayName < $1.translation.displayName }
        downloadedDS.items = downloadedItems

        // move the cell
        let newLocalIndexPath: IndexPath = cast(downloadedDS.indexPath(for: newItem))
        let newGlobalIndexPath = globalIndexPathForLocalIndexPath(newLocalIndexPath, dataSource: downloadedDS)
        ds_reusableViewDelegate?.ds_moveItem(at: globalIndexPath, to: newGlobalIndexPath)
    }

    func translationsBasicDataSource(_ dataSource: TranslationsBasicDataSource, onShouldStartDownload item: TranslationFull) {
        // download the translation
        let destinationPath = Files.translationsPathComponent.stringByAppendingPath(item.translation.rawFileName)
        let download = Download(url: item.translation.fileURL, resumePath: destinationPath.resumePath, destinationPath: destinationPath)
        let responses = self.downloader.download([download])

        guard let response = responses.first else {
            return
        }

        // update the item to be downloading
        let newItem = TranslationFull(translation: item.translation, downloaded: false, downloadResponse: response)
        var newItems = dataSource.items
        newItems[cast(newItems.index(of: item))] = newItem
        dataSource.items = newItems

        // observe download progress
        downloadingObservers[newItem.translation.id] = DownloadingObserver(translation: newItem, dataSource: self)
    }

    func translationsBasicDataSource(_ dataSource: TranslationsBasicDataSource, onShouldCancelDownload item: TranslationFull) {
        let observer = downloadingObservers[item.translation.id]
        observer?.cancel()
    }
}

private class DownloadingObserver: NSObject {
    private weak var dataSource: TranslationsDataSource?

    let translation: TranslationFull

    init(translation: TranslationFull, dataSource: TranslationsDataSource) {
        self.translation = translation
        self.dataSource = dataSource
        super.init()
        start()
    }

    deinit {
        stop()
    }

    func cancel() {
        stop()
        translation.downloadResponse?.cancel()
    }

    func stop() {
        translation.downloadResponse?.onCompletion = nil
        kvoController.unobserveAll()
    }

    func start() {
        let response: DownloadNetworkResponse = cast(translation.downloadResponse)
        kvoController.observe(response.progress, keyPath: "fractionCompleted",
                              options: [.initial, .new],
                              block: { [weak self] (_, progress, change) in
                                if let progress = progress as? Progress, let translation = self?.translation {
                                    Queue.main.async {
                                        self?.dataSource?.onDownloadProgressUpdated(progress: Float(progress.fractionCompleted), for: translation)
                                    }
                                }
        })
        response.onCompletion = { [weak self] result in
            if let translation = self?.translation {
                Queue.main.async {
                    switch result {
                    case .success:
                        self?.dataSource?.onDownloadCompleted(for: translation)
                    case .failure(let error):
                        self?.dataSource?.onDownloadCompleted(withError: error, for: translation)
                    }

                }
            }
        }
    }
}
