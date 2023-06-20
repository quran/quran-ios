//
//  ReadingSelectorViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation
import NoorUI
import QuranKit
import ReadingService

class ReadingSelectorViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        preferences.$reading
            .prepend(preferences.reading)
            .map { $0 as Reading? }
            .assign(to: &$selectedReading)
    }

    // MARK: Internal

    @Published var selectedReading: Reading?

    var readings: [ReadingInfo<Reading>] {
        Reading.sortedReadings.map { ReadingInfo($0) }
    }

    func showReading(_ reading: Reading) {
        preferences.reading = reading
    }

    // MARK: Private

    private let preferences = ReadingPreferences.shared
}

private extension ReadingInfo where Value == Reading {
    init(_ reading: Reading) {
        self.init(
            value: reading,
            title: reading.title,
            description: reading.description,
            properties: reading.propertiesDescription
        )
    }
}
