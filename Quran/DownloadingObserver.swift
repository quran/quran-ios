//
//  DownloadingObserver.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/17.
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

protocol DownloadingObserverDelegate: class {
    associatedtype Item: Downloadable

    func onDownloadProgressUpdated(progress: Float, for item: Item)
    func onDownloadCompleted(withError error: Error, for item: Item)
    func onDownloadCompleted(for item: Item)
}

private class DownloadingObserverDelegateBoxBase<Item: Downloadable>: DownloadingObserverDelegate {

    func onDownloadProgressUpdated(progress: Float, for item: Item) { unimplemented() }
    func onDownloadCompleted(withError error: Error, for item: Item) { unimplemented() }
    func onDownloadCompleted(for item: Item) { unimplemented() }
}

private class DownloadingObserverDelegateBox<D: DownloadingObserverDelegate>: DownloadingObserverDelegateBoxBase<D.Item> {

    weak var delegate: D?
    init(_ delegate: D?) {
        self.delegate = delegate
    }

    override func onDownloadProgressUpdated(progress: Float, for item: D.Item) { delegate?.onDownloadProgressUpdated(progress: progress, for: item) }
    override func onDownloadCompleted(withError error: Error, for item: D.Item) { delegate?.onDownloadCompleted(withError: error, for: item) }
    override func onDownloadCompleted(for item: D.Item) { delegate?.onDownloadCompleted(for: item) }
}

final class AnyDownloadingObserverDelegate<Item: Downloadable>: DownloadingObserverDelegate {
    private let box: DownloadingObserverDelegateBoxBase<Item>

    init<D: DownloadingObserverDelegate>(_ delegate: D) where D.Item == Item {
        box = DownloadingObserverDelegateBox(delegate)
    }

    func onDownloadProgressUpdated(progress: Float, for item: Item) { box.onDownloadProgressUpdated(progress: progress, for: item) }
    func onDownloadCompleted(withError error: Error, for item: Item) { box.onDownloadCompleted(withError: error, for: item) }
    func onDownloadCompleted(for item: Item) { box.onDownloadCompleted(for: item) }
}

class DownloadingObserver<Item: Downloadable>: NSObject, QProgressListener {
    private var observer: AnyDownloadingObserverDelegate<Item>?

    let item: Item

    private var stopped = Protected<Bool>(false)

    var isStopped: Bool {
        return stopped.value
    }

    init<D: DownloadingObserverDelegate>(item: Item, delegate: D) where D.Item == Item {
        self.item = item
        self.observer = AnyDownloadingObserverDelegate(delegate)
        super.init()
        start()
    }

    func cancel() {
        stop()
        item.response?.cancel()
    }

    func stop() {
        stopped.value = true
    }

    func start() {
        guard let response = item.response else {
            return
        }
        stopped.value = false

        response.progress.progressListeners.insert(self)
        response.promise.done(on: .main) { [weak self] _ -> Void in
            guard let `self` = self, !self.stopped.value else {
                return
            }
            self.observer?.onDownloadCompleted(for: self.item)
        }.catch(on: .main) { [weak self] error in
            guard let `self` = self, !self.stopped.value else {
                return
            }
            self.observer?.onDownloadCompleted(withError: error, for: self.item)
        }.finally { [weak self] in
            self?.stopped.value = true
        }
        onProgressUpdated(to: response.progress.progress)
    }

    func onProgressUpdated(to progress: Double) {
        DispatchQueue.main.async {
            guard !self.stopped.value else {
                return
            }
            self.observer?.onDownloadProgressUpdated(progress: Float(progress), for: self.item)
        }
    }
}
