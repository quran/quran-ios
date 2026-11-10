//
//  ReadingSelectorViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation
import Localization
import NoorUI
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
    /// The readings this app can load, or `nil` until they're known.
    @Published var availableReadings: Set<Reading>?

    var readingGroups: [ReadingGroup<Reading>] {
        [
            ReadingGroup(
                id: "uthmani",
                title: l("reading.selector.group.uthmani"),
                readings: readingInfos([.hafs_1405, .hafs_1441, .hafs_1440, .hafs_1439, .hafs_1421])
            ),
            ReadingGroup(
                id: "tajweed",
                title: l("reading.selector.group.tajweed"),
                readings: readingInfos([.tajweed])
            ),
            ReadingGroup(
                id: "indopak",
                title: l("reading.selector.group.indopak"),
                readings: readingInfos([.indoPak])
            ),
        ]
        .filter { !$0.readings.isEmpty }
    }

    func start() async {
        // Offer only readings this app can load, so picking one never leaves the reader without resources.
        availableReadings = await resources.availableReadings()
        async let reading: () = listenToReadingChanges()
        async let resources: () = listenToResourcesEvents()
        _ = await (reading, resources)
    }

    func showReading(_ reading: Reading) {
        preferences.reading = reading
    }

    func retry() async {
        await resources.retry()
    }

    // MARK: Private

    private let preferences = ReadingPreferences.shared
    private let resources: ReadingResourcesService

    private func readingInfos(_ readings: [Reading]) -> [ReadingInfo<Reading>] {
        readings
            .filter { availableReadings?.contains($0) ?? true }
            .map(ReadingInfo.init)
    }

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
        let tags: [NoorTag] = switch reading {
        case .hafs_1441, .hafs_1439:
            [NoorTag(
                title: l("reading.selector.badge.large-screen-optimized"),
                tone: .accent
            )]
        case .indoPak:
            [NoorTag(
                title: l("reading.selector.badge.experimental"),
                tone: .red
            )]
        default:
            []
        }

        self.init(
            value: reading,
            title: reading.title,
            description: reading.description,
            properties: reading.properties,
            tags: tags
        )
    }
}
