//
//  HistoryProgressListener.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import AsyncAlgorithms
import BatchDownloader
import Utilities

actor HistoryProgressListener {
    var values: [Double] = []
    var cancellable: CancellableTask?

    init(_ subject: AsyncPublisher<DownloadProgress>) async {
        let taskStarted = AsyncChannel<Void>()
        cancellable = Task {
            await taskStarted.send(())
            for await progress in subject {
                if progress.progress != values.last {
                    values.append(progress.progress)
                }
            }
        }
        .asCancellableTask()
        await taskStarted.next()
    }
}
