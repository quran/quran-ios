//
//  ReviewPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 2021-12-14.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Foundation
import Preferences

final class ReviewPersistence {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ReviewPersistence()

    // MARK: Internal

    @Preference(appOpenedCounter)
    var appOpenedCounter: Int

    @TransformedPreference(appInstalledDate, transformer: dateTransfomer)
    var appInstalledDate: Date

    @TransformedPreference(requestReviewDate, transformer: optionalTransfomer(of: dateTransfomer))
    var requestReviewDate: Date?

    // MARK: Private

    private static let appOpenedCounter = PreferenceKey<Int>(key: "appOpenedCounter", defaultValue: 0)
    private static let appInstalledDate = PreferenceKey<TimeInterval>(key: "appInstalledDate", defaultValue: 0)
    private static let requestReviewDate = PreferenceKey<TimeInterval?>(key: "requestReviewDate", defaultValue: nil)

    private static let dateTransfomer = PreferenceTransformer<TimeInterval, Date>(
        rawToValue: { Date(timeIntervalSince1970: $0) },
        valueToRaw: { $0.timeIntervalSince1970 }
    )
}
