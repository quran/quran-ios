//
//  AudioDownloadsDataSource.swift
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

protocol AudioDownloadsDataSourceDelegate: class {
    func audioDownloadsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error)
}

class AudioDownloadsDataSource: BasicDataSource<DownloadableQariAudio, AudioDownloadTableViewCell> {

    private let deletionInteractor: AnyInteractor<Qari, Void>
    private let downloader: DownloadManager
    private let ayahsDownloader: AnyInteractor<AyahsAudioDownloadRequest, DownloadBatchResponse>
    fileprivate let qariAudioDownloadRetriever: AnyInteractor<[Qari], [QariAudioDownload]>
    fileprivate var downloadingObservers: [Qari: DownloadingObserver<DownloadableQariAudio>] = [:]

    weak var delegate: AudioDownloadsDataSourceDelegate?

    var onEditingChanged: (() -> Void)?

    init(downloader: DownloadManager,
         ayahsDownloader: AnyInteractor<AyahsAudioDownloadRequest, DownloadBatchResponse>,
         qariAudioDownloadRetriever: AnyInteractor<[Qari], [QariAudioDownload]>,
         deletionInteractor: AnyInteractor<Qari, Void>) {
        self.downloader = downloader
        self.ayahsDownloader = ayahsDownloader
        self.qariAudioDownloadRetriever = qariAudioDownloadRetriever
        self.deletionInteractor = deletionInteractor
        super.init()
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
        let item = self.item(at: indexPath)
        return item.response == nil && item.audio.downloadedSizeInBytes != 0
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    commit editingStyle: UITableViewCellEditingStyle,
                                    forItemAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }

        let item = self.item(at: indexPath)

        Analytics.shared.deletingQuran(qari: item.audio.qari)
        deletionInteractor
            .execute(item.audio.qari)
            .then(on: .main) { () -> Void in

                let newDownload = QariAudioDownload(qari: item.audio.qari, downloadedSizeInBytes: 0, downloadedSuraCount: 0)
                let newItem = DownloadableQariAudio(audio: newDownload, response: nil)
                self.items[indexPath.item] = newItem

                self.ds_reusableViewDelegate?.ds_reloadItems(at: [indexPath], with: .automatic)
            }.catch(on: .main) { error in
                self.delegate?.audioDownloadsDataSource(self, errorOccurred: error)
            }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: AudioDownloadTableViewCell,
                                    with item: DownloadableQariAudio,
                                    at indexPath: IndexPath) {
        cell.configure(with: item.audio)
        cell.downloadButton.state = item.state
        cell.onShouldStartDownload = { [weak self] in
            self?.onShouldStartDownload(item: item)
        }

        cell.onShouldCancelDownload = { [weak self] in
            self?.onShouldCancelDownload(item: item)
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        (cell as? AudioDownloadTableViewCell)?.downloadButton.state = item(at: indexPath).state
    }

    override var items: [DownloadableQariAudio] {
        didSet {
            downloadingObservers.forEach { $1.stop() }
            downloadingObservers.removeAll()

            for item in items where item.response != nil {
                downloadingObservers[item.audio.qari] = DownloadingObserver(item: item, delegate: self)
            }
        }
    }

    private var cancelled: Protected<Bool> = Protected(false)

    func onShouldStartDownload(item: DownloadableQariAudio) {
        cancelled.value = false

        Analytics.shared.downloadingQuran(qari: item.audio.qari)
        // download the audio
        ayahsDownloader
            .execute(AyahsAudioDownloadRequest(start: Quran.startAyah, end: Quran.lastAyah, qari: item.audio.qari))
            .then { response -> Void in

                guard !self.cancelled.value else {
                    response.cancel()
                    return
                }

                guard let itemIndex = self.items.index(of: item) else {
                    return
                }

                // update the item to be downloading
                let newItem = DownloadableQariAudio(audio: item.audio, response: response)
                self.items[itemIndex] = newItem

                // observe download progress
                self.downloadingObservers[newItem.audio.qari] = DownloadingObserver(item: newItem, delegate: self)

            }.suppress()
    }

    func onShouldCancelDownload(item: DownloadableQariAudio) {
        if let observer = downloadingObservers[item.audio.qari] {
            observer.cancel()
        } else {
            cancelled.value = true // if cancelled early
        }

        guard let itemIndex = self.items.index(of: item) else {
            return
        }

        // update the item to be not downloading
        self.items[itemIndex] = DownloadableQariAudio(audio: item.audio, response: nil)
    }
}

extension AudioDownloadsDataSource: DownloadingObserverDelegate {
    func onDownloadProgressUpdated(progress: Float, for item: DownloadableQariAudio) {
        guard let localIndexPath = self.indexPath(for: item) else {
            CLog("Cannot updated progress for audio \(item.audio.qari.name)")
            return
        }
        let cell = self.ds_reusableViewDelegate?.ds_cellForItem(at: localIndexPath) as? AudioDownloadTableViewCell

        let scale: Float = 2_000
        let oldValue = floor((cell?.downloadButton.state.progress ?? 0) * scale)
        let newValue = floor(item.state.progress * scale)

        cell?.downloadButton.state = item.state

        if newValue - oldValue > 0.9 {
            reload(item: item, response: item.response)
            CLog("Reloading \(newValue), \(oldValue)")
        }
    }

    func onDownloadCompleted(withError error: Error, for item: DownloadableQariAudio) {
        guard let localIndexPath = indexPath(for: item) else {
            CLog("Cannot error download for audio \(item.audio.qari.name)")
            return
        }

        // update the item to be not downloading
        let newItem = DownloadableQariAudio(audio: item.audio, response: nil)
        self.items[localIndexPath.item] = newItem

        // update the UI
        delegate?.audioDownloadsDataSource(self, errorOccurred: error)
        let cell = ds_reusableViewDelegate?.ds_cellForItem(at: localIndexPath) as? AudioDownloadTableViewCell
        cell?.downloadButton.state = newItem.state
    }

    func onDownloadCompleted(for item: DownloadableQariAudio) {

        guard let localIndexPath = indexPath(for: item) else {
            CLog("Cannot complete download for audio \(item.audio.qari.name)")
            return
        }
        // remove old observer
        let observer = downloadingObservers.removeValue(forKey: item.audio.qari)
        observer?.stop()

        // update the cell
        let cell = self.ds_reusableViewDelegate?.ds_cellForItem(at: localIndexPath) as? AudioDownloadTableViewCell
        cell?.downloadButton.state = .downloaded

        reload(item: item, response: nil)
    }

    private func reload(item: DownloadableQariAudio, response: DownloadBatchResponse?) {
        qariAudioDownloadRetriever.execute([item.audio.qari])
            .then(on: .main) { audios -> Void in
                guard let audio = audios.first else {
                    return
                }
                guard let localIndexPath = self.indexPath(for: item) else {
                    CLog("Cannot get audio indexPath for \(item.audio.qari.name)")
                    return
                }

                let oldItem = self.items[localIndexPath.item]
                let finalResponse: DownloadBatchResponse?
                if response == nil || oldItem.response == nil {
                    finalResponse = nil
                } else {
                    finalResponse = response
                }

                // update the item response
                let newItem = DownloadableQariAudio(audio: audio, response: finalResponse)
                self.items[localIndexPath.item] = newItem

                let cell = self.ds_reusableViewDelegate?.ds_cellForItem(at: localIndexPath) as? AudioDownloadTableViewCell
                cell?.configure(with: audio)

            }.suppress()
    }
}
