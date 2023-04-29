//
//  HistoryProgressListener.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import BatchDownloader
import Combine

final class HistoryProgressListener {
    var values: [Double] = []
    var cancellable: AnyCancellable?

    init(_ subject: AnyPublisher<DownloadProgress, Never>) {
        cancellable = subject.sink { [weak self] progress in
            self?.values.append(progress.progress)
        }
    }
}
