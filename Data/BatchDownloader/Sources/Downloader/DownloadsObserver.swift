//
//  DownloadsObserver.swift
//
//
//  Created by Mohamed Afifi on 2023-07-02.
//

import Combine
import Foundation
import Utilities
import VLogging

@MainActor
public final class DownloadsObserver<Key: Hashable> {
    // MARK: Lifecycle

    public init(extractKey: @escaping (DownloadBatchResponse) -> Key?, showError: @escaping @MainActor (Error) -> Void) {
        self.extractKey = extractKey
        self.showError = showError
    }

    // MARK: Public

    public private(set) var runningDownloads: Set<DownloadBatchResponse> = []

    public var progressPublisher: AnyPublisher<[Key: Double], Never> {
        progress
            .throttle(for: .seconds(0.1), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }

    public func observe(_ downloads: Set<DownloadBatchResponse>) async {
        runningDownloads.formUnion(downloads)

        for download in downloads {
            cancellableTasks.task { [weak self] in
                do {
                    for try await progress in download.progress {
                        await self?.progressUpdated(of: download, progress: progress.progress)
                    }
                } catch {
                    self?.showError(error)
                }
                self?.finish(download)
            }
        }
    }

    // MARK: Internal

    let extractKey: (DownloadBatchResponse) -> Key?
    let showError: @MainActor (Error) -> Void

    // MARK: Private

    private let progress = CurrentValueSubject<[Key: Double], Never>([:])
    private var cancellableTasks = Set<CancellableTask>()

    private func finish(_ download: DownloadBatchResponse) {
        runningDownloads.remove(download)
        if let key = extractKey(download) {
            progress.value.removeValue(forKey: key)
        }
    }

    private func progressUpdated(of batch: DownloadBatchResponse, progress newProgress: Double) async {
        // Ignore if it's not running (e.g. cancelled).
        guard runningDownloads.contains(batch) else {
            return
        }

        guard let key = extractKey(batch) else {
            logger.debug("Cannot find key \(Key.self) for download \(batch)")
            return
        }
        progress.value[key] = newProgress
    }
}
