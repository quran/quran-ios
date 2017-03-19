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
    func translationsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error)
}

class TranslationsDataSource: CompositeDataSource, TranslationsBasicDataSourceDelegate {

    weak var delegate: TranslationsDataSourceDelegate?

    private let downloader: DownloadManager
    private let deletionInteractor: AnyInteractor<TranslationFull, TranslationFull>
    private let versionUpdater: AnyInteractor<[Translation], [TranslationFull]>

    private let downloadedDS: AnyBasicDataSourceRepresentable<TranslationFull>
    private let pendingDS: AnyBasicDataSourceRepresentable<TranslationFull>

    private var downloadingObservers: [Int: DownloadingObserver] = [:]

    public init(downloader: DownloadManager,
                deletionInteractor: AnyInteractor<TranslationFull, TranslationFull>,
                versionUpdater: AnyInteractor<[Translation], [TranslationFull]>,
                pendingDataSource: AnyBasicDataSourceRepresentable<TranslationFull>,
                downloadedDataSource: AnyBasicDataSourceRepresentable<TranslationFull>,
                headerReuseId: String) {
        self.downloader = downloader
        self.deletionInteractor = deletionInteractor
        self.versionUpdater = versionUpdater
        pendingDS = pendingDataSource
        downloadedDS = downloadedDataSource

        super.init(sectionType: .multi)

        let headers = TranslationsHeaderSupplementaryViewCreator(identifier: headerReuseId)
        headers.setSectionedItems([
            NSLocalizedString("downloaded_translations", tableName: "Android", comment: ""),
            NSLocalizedString("available_translations", tableName: "Android", comment: "")
            ])

        set(headerCreator: headers)
        add(downloadedDS.dataSource)
        add(pendingDS.dataSource)
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

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let ds = dataSource(at: indexPath.section)
        return ds === downloadedDS.dataSource
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt globalIndexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let localIndexPath = localIndexPathForGlobalIndexPath(globalIndexPath, dataSource: downloadedDS.dataSource)
        let item = downloadedDS.item(at: localIndexPath)

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

    private func move(item: TranslationFull,
                      atLocalPath localIndexPath: IndexPath,
                      newItem: TranslationFull,
                      from: AnyBasicDataSourceRepresentable<TranslationFull>,
                      to: AnyBasicDataSourceRepresentable<TranslationFull>) -> IndexPath {

        // remove from old location
        from.items.remove(at: localIndexPath.item)

        // add in new location
        var list = to.items
        list.append(newItem)
        list.sort()
        to.items = list

        // move the cell
        let newLocalIndexPath: IndexPath = cast(to.indexPath(for: newItem))
        let newGlobalIndexPath = globalIndexPathForLocalIndexPath(newLocalIndexPath, dataSource: to.dataSource)
        return newGlobalIndexPath
    }

    func setItems(items: [TranslationFull]) {
        downloadingObservers.forEach { $1.stop() }
        downloadingObservers.removeAll()

        pendingDS.items    = items.filter { !$0.downloaded }.sorted()
        downloadedDS.items = items.filter {  $0.downloaded }.sorted()

        for item in items {
            if item.downloadResponse != nil {
                downloadingObservers[item.translation.id] = DownloadingObserver(translation: item, dataSource: self)
            }
        }
    }

    private func indexPathFor(translation: TranslationFull) -> (AnyBasicDataSourceRepresentable<TranslationFull>, IndexPath)? {
        let dataSources = [downloadedDS, pendingDS]
        for ds in dataSources {
            if let indexPath = ds.indexPath(for: translation) {
                return (ds, indexPath)
            }
        }
        return nil
    }

    func onDownloadProgressUpdated(progress: Float, for translation: TranslationFull) {
        guard let (ds, localIndexPath) = indexPathFor(translation: translation) else {
            CLog("Cannot updated progress for translation \(translation.translation.displayName)")
            return
        }
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: ds.dataSource)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.state = translation.state
    }

    func onDownloadCompleted(withError error: Error, for translation: TranslationFull) {
        guard let (ds, localIndexPath) = indexPathFor(translation: translation) else {
            CLog("Cannot updated progress for translation \(translation.translation.displayName)")
            return
        }

        // update the item to be not downloading
        let newItem = TranslationFull(translation: translation.translation, downloadResponse: nil)
        var newItems = ds.items
        newItems[localIndexPath.item] = newItem
        ds.items = newItems

        // update the UI
        delegate?.translationsDataSource(self, errorOccurred: error)
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: ds.dataSource)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.state = newItem.state
    }

    func onDownloadCompleted(for translation: TranslationFull) {
        guard let (ds, localIndexPath) = indexPathFor(translation: translation) else {
            CLog("Cannot complete download for translation \(translation.translation.displayName)")
            return
        }
        let globalIndexPath = globalIndexPathForLocalIndexPath(localIndexPath, dataSource: ds.dataSource)

        // remove old observer
        let observer = downloadingObservers.removeValue(forKey: translation.translation.id)
        observer?.stop()

        // update the cell
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: globalIndexPath) as? TranslationTableViewCell
        cell?.downloadButton.state = .downloaded

        versionUpdater
            .execute([translation.translation])
            .then(on: .main) { newItems  -> Void in
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

    func translationsBasicDataSource(_ dataSource: AbstractDataSource, onShouldStartDownload item: TranslationFull) {

        guard let (ds, _) = indexPathFor(translation: item) else {
            return
        }

        // download the translation
        let destinationPath = Files.translationsPathComponent.stringByAppendingPath(item.translation.rawFileName)
        let download = Download(url: item.translation.fileURL, resumePath: destinationPath.resumePath, destinationPath: destinationPath)
        let responses = self.downloader.download([download])

        guard let response = responses.first else {
            return
        }

        // update the item to be downloading
        let newItem = TranslationFull(translation: item.translation, downloadResponse: response)
        var newItems = ds.items
        newItems[cast(newItems.index(of: item))] = newItem
        ds.items = newItems

        // observe download progress
        downloadingObservers[newItem.translation.id] = DownloadingObserver(translation: newItem, dataSource: self)
    }

    func translationsBasicDataSource(_ dataSource: AbstractDataSource, onShouldCancelDownload item: TranslationFull) {
        let observer = downloadingObservers[item.translation.id]
        observer?.cancel()
    }
}

extension TranslationsDataSource: DownloadingObserverDelegate {
}

protocol DownloadingObserverDelegate: class {
    func onDownloadProgressUpdated(progress: Float, for translation: TranslationFull)
    func onDownloadCompleted(withError error: Error, for translation: TranslationFull)
    func onDownloadCompleted(for translation: TranslationFull)
}

private class DownloadingObserver: NSObject {
    private weak var dataSource: DownloadingObserverDelegate?

    let translation: TranslationFull

    init(translation: TranslationFull, dataSource: DownloadingObserverDelegate) {
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
                              block: { [weak self] (_, progress, _) in
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
