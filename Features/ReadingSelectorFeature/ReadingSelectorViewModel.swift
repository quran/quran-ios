//
//  ReadingSelectorViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation
import QuranKit
import ReadingService

@MainActor
class ReadingSelectorViewModel: ObservableObject {
    // MARK: Lifecycle

    init(resources: ReadingResourcesService) {
        self.resources = resources
    }

    // MARK: Internal

    @Published var selectedReading: Reading?
    @Published var progress: Double?
    @Published var error: Error?

    var readings: [ReadingInfo<Reading>] {
        Reading.sortedReadings.map { ReadingInfo($0) }
    }

    func start() async {
        async let reading: () = listenToReadingChanges()
        async let resources: () = listenToResourcesEvents()
        _ = await (reading, resources)
    }

    func showReading(_ reading: Reading) {
        preferences.reading = reading
    }

    // MARK: Private

    private let preferences = ReadingPreferences.shared
    private let resources: ReadingResourcesService

    private func listenToReadingChanges() async {
        let readingsSequence = preferences.$reading
            .prepend(preferences.reading)
            .values()
        for await reading in readingsSequence {
            selectedReading = reading
        }
    }

    private func listenToResourcesEvents() async {
        let resourceStatuses = resources.publisher.values()
        for await status in resourceStatuses {
            switch status {
            case .downloading(let progress):
                self.progress = progress
                error = nil
            case .error(let error):
                progress = nil
                self.error = error
            case .ready:
                progress = nil
                error = nil
            }
        }
    }
}

private extension ReadingInfo where Value == Reading {
    init(_ reading: Reading) {
        self.init(
            value: reading,
            title: reading.title,
            description: reading.description,
            properties: reading.properties
        )
    }
}
