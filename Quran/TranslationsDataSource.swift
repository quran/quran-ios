//
//  TranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
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

protocol TranslationsDataSourceDelegate: class {
    func translationsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error)
}

class TranslationsDataSource: CompositeDataSource, TranslationsBasicDataSourceDelegate {

    var onEditingChanged: (() -> Void)?

    weak var delegate: TranslationsDataSourceDelegate?

    private let downloader: DownloadManager
    private let deletionInteractor: AnyInteractor<TranslationFull, TranslationFull>
    fileprivate let versionUpdater: AnyInteractor<[Translation], [TranslationFull]>

    let downloadedDS: TranslationsBasicDataSource
    let pendingDS: TranslationsBasicDataSource

    fileprivate var downloadingObservers: [Int: DownloadingObserver<TranslationFull>] = [:]

    public init(downloader: DownloadManager,
                deletionInteractor: AnyInteractor<TranslationFull, TranslationFull>,
                versionUpdater: AnyInteractor<[Translation], [TranslationFull]>,
                pendingDataSource: TranslationsBasicDataSource,
                downloadedDataSource: TranslationsBasicDataSource) {
        self.downloader = downloader
        self.deletionInteractor = deletionInteractor
        self.versionUpdater = versionUpdater
        pendingDS = pendingDataSource
        downloadedDS = downloadedDataSource

        super.init(sectionType: .multi)

        let headers = TranslationsHeaderSupplementaryViewCreator()
        headers.setSectionedItems([
            NSLocalizedString("downloaded_translations", tableName: "Android", comment: ""),
            NSLocalizedString("available_translations", tableName: "Android", comment: "")])

        set(headerCreator: headers)
        add(downloadedDS)
        add(pendingDS)
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

    override func ds_collectionView(_ collectionView: GeneralCollectionView, willBeginEditingItemAt indexPath: IndexPath) {
        // call it in the next cycle to give isEditing a chance to change
        DispatchQueue.main.async {
            self.onEditingChanged?()
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndEditingItemAt indexPath: IndexPath) {
        onEditingChanged?()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        let ds = dataSource(at: indexPath.section)
        return ds === downloadedDS
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    commit editingStyle: UITableViewCellEditingStyle,
                                    forItemAt globalIndexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let localIndexPath = localIndexPathForGlobalIndexPath(globalIndexPath, dataSource: downloadedDS)
        let item = downloadedDS.item(at: localIndexPath)

        Analytics.shared.deleting(translation: item.translation)

        deletionInteractor
            .execute(item)
            .then(on: .main) { newItem -> Void in

                let newGlobalIndexPath = self.move(item: item,
                                                   atLocalPath: localIndexPath,
                                                   newItem: newItem,
                                                   from: self.downloadedDS,
                                                   to: self.pendingDS)
                self.ds_reusableViewDelegate?.ds_performBatchUpdates({
                    self.ds_reusableViewDelegate?.ds_deleteItems(at: [globalIndexPath], with: .left)
                    self.ds_reusableViewDelegate?.ds_insertItems(at: [newGlobalIndexPath], with: .right)
                }, completion: nil)
            }.catch(on: .main) { error in
                self.delegate?.translationsDataSource(self, errorOccurred: error)
        }
    }

    fileprivate func move(item: TranslationFull,
                          atLocalPath localIndexPath: IndexPath,
                          newItem: TranslationFull,
                          from: TranslationsBasicDataSource,
                          to: TranslationsBasicDataSource) -> IndexPath {

        // remove from old location
        from.items.remove(at: localIndexPath.item)

        // add in new location
        var list = to.items
        list.append(newItem)
        list.sort()
        to.items = list

        // move the cell
        let newLocalIndexPath: IndexPath = cast(to.indexPath(for: newItem))
        let newGlobalIndexPath = globalIndexPathForLocalIndexPath(newLocalIndexPath, dataSource: to)
        return newGlobalIndexPath
    }

    func setItems(items: [TranslationFull]) {
        downloadingObservers.forEach { $1.stop() }
        downloadingObservers.removeAll()

        pendingDS.items    = items.filter { !$0.isDownloaded }.sorted()
        downloadedDS.items = items.filter { $0.isDownloaded }.sorted()

        for item in items where item.response != nil {
            downloadingObservers[item.translation.id] = DownloadingObserver(item: item, delegate: self)
        }
    }

    fileprivate func indexPathFor(translation: TranslationFull) -> (TranslationsBasicDataSource, IndexPath)? {
        let dataSources = [downloadedDS, pendingDS]
        for ds in dataSources {
            if let indexPath = ds.indexPath(for: translation) {
                return (ds, indexPath)
            }
        }
        return nil
    }

    func translationsBasicDataSource(_ dataSource: AbstractDataSource, onShouldStartDownload item: TranslationFull) {

        guard let (ds, _) = indexPathFor(translation: item) else {
            return
        }

        Analytics.shared.downloading(translation: item.translation)

        // download the translation
        let destinationPath = Files.translationsPathComponent.stringByAppendingPath(item.translation.rawFileName)
        let download = Download(url: item.translation.fileURL, resumePath: destinationPath.resumePath, destinationPath: destinationPath)
        let responses = self.downloader.download([download])

        guard let response = responses.first else {
            return
        }

        // update the item to be downloading
        let newItem = TranslationFull(translation: item.translation, response: response)
        var newItems = ds.items
        newItems[cast(newItems.index(of: item))] = newItem
        ds.items = newItems

        // observe download progress
        downloadingObservers[newItem.translation.id] = DownloadingObserver(item: newItem, delegate: self)
    }

    func translationsBasicDataSource(_ dataSource: AbstractDataSource, onShouldCancelDownload item: TranslationFull) {
        let observer = downloadingObservers[item.translation.id]
        observer?.cancel()
    }
}

extension TranslationsDataSource: DownloadingObserverDelegate {
    func onDownloadProgressUpdated(progress: Float, for translation: TranslationFull) {
        guard let (ds, localIndexPath) = indexPathFor(translation: translation) else {
            CLog("Cannot updated progress for translation \(translation.translation.displayName)")
            return
        }
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: ds)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.state = translation.state
    }

    func onDownloadCompleted(withError error: Error, for translation: TranslationFull) {
        guard let (ds, localIndexPath) = indexPathFor(translation: translation) else {
            CLog("Cannot error download for translation \(translation.translation.displayName)")
            return
        }

        // update the item to be not downloading
        let newItem = TranslationFull(translation: translation.translation, response: nil)
        var newItems = ds.items
        newItems[localIndexPath.item] = newItem
        ds.items = newItems

        // update the UI
        delegate?.translationsDataSource(self, errorOccurred: error)
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: ds)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.state = newItem.state
    }

    func onDownloadCompleted(for translation: TranslationFull) {

        versionUpdater
            .execute([translation.translation])
            .then(on: .main) { newItems -> Void in

                guard let (ds, localIndexPath) = self.indexPathFor(translation: translation) else {
                    CLog("Cannot complete download for translation \(translation.translation.displayName)")
                    return
                }
                let globalIndexPath = self.globalIndexPathForLocalIndexPath(localIndexPath, dataSource: ds)

                // remove old observer
                let observer = self.downloadingObservers.removeValue(forKey: translation.translation.id)
                observer?.stop()

                // update the cell
                let cell = self.ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
                cell?.downloadButton.state = .downloaded
                cell?.checkbox.isHidden = !self.downloadedDS.isSelectable
                cell?.setSelection(false)

                let newGlobalIndexPath = self.move(item: translation,
                                                   atLocalPath: localIndexPath,
                                                   newItem: newItems[0],
                                                   from: ds,
                                                   to: self.downloadedDS)
                self.ds_reusableViewDelegate?.ds_moveItem(at: globalIndexPath, to: newGlobalIndexPath)
            }.catch(on: .main) { error in
                self.delegate?.translationsDataSource(self, errorOccurred: error)
        }
    }
}
