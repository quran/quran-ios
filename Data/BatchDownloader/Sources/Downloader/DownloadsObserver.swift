//
//  DownloadsObserver.swift
//
//
//  Created by Mohamed Afifi on 2023-07-02.
//

import Foundation
import Utilities
import VLogging

@MainActor
public final class DownloadsObserver<Key: Hashable> {
    // MARK: Lifecycle

    public init(extractKey: @escaping (DownloadBatchResponse) -> Key?, showError: @escaping (Error) -> Void) {
        self.extractKey = extractKey
        self.showError = showError
    }

    // MARK: Public

    @Published public private(set) var progress: [Key: Double] = [:]
    public private(set) var runningDownloads: Set<DownloadBatchResponse> = []

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

                guard let self else { return }
                runningDownloads.remove(download)
                if let key = extractKey(download) {
                    progress.removeValue(forKey: key)
                }
            }
        }
    }

    // MARK: Internal

    let extractKey: (DownloadBatchResponse) -> Key?
    let showError: (Error) -> Void

    // MARK: Private

    private var cancellableTasks = Set<CancellableTask>()

    private func progressUpdated(of batch: DownloadBatchResponse, progress newProgress: Double) async {
        // Ignore if it's not running (e.g. cancelled).
        guard runningDownloads.contains(batch) else {
            return
        }

        guard let key = extractKey(batch) else {
            logger.debug("Cannot find key \(Key.self) for download \(batch)")
            return
        }
        progress[key] = newProgress
    }
}
