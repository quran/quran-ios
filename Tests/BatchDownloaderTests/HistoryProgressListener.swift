//
//  HistoryProgressListener.swift
//
//
//  Created by Mohamed Afifi on 2022-01-23.
//

import BatchDownloader

final class HistoryProgressListener: QProgressListener {
    var values: [Double] = []

    func onProgressUpdated(to progress: Double) {
        values.append(progress)
    }
}
