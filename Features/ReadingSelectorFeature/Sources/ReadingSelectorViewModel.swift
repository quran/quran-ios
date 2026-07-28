//
//  ReadingSelectorViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation
import Localization
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

    var readingGroups: [ReadingGroup<Reading>] {
        [
            ReadingGroup(
                id: "uthmani",
                title: l("reading.selector.group.uthmani"),
                readings: [
                    .hafs_1405,
                    .hafs_1441,
                    .hafs_1440,
                    .hafs_1439,
                    .hafs_1421,
                ].map(ReadingInfo.init)
            ),
            ReadingGroup(
                id: "tajweed",
                title: l("reading.selector.group.tajweed"),
                readings: [Reading.tajweed].map(ReadingInfo.init)
            ),
            ReadingGroup(
                id: "naskh",
                title: l("reading.selector.group.naskh"),
                readings: [Reading.naskh].map(ReadingInfo.init)
            ),
        ]
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
        let badge: ReadingBadge? = switch reading {
        case .hafs_1441, .hafs_1439:
            ReadingBadge(
                title: l("reading.selector.badge.large-screen-optimized"),
                style: .informational
            )
        case .naskh:
            ReadingBadge(
                title: l("reading.selector.badge.experimental"),
                style: .experimental
            )
        default:
            nil
        }

        self.init(
            value: reading,
            title: reading.title,
            description: reading.description,
            properties: reading.properties,
            badge: badge
        )
    }
}
