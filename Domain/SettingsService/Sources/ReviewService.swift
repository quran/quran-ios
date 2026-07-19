//
//  ReviewService.swift
//  Quran
//
//  Created by Muhammad Umer on 4/11/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Analytics
import Foundation
import StoreKit
import Utilities

@MainActor
public struct ReviewService {
    // MARK: Lifecycle

    public init(analytics: AnalyticsLibrary) {
        self.analytics = analytics
    }

    // MARK: Public

    public func checkForReview(in window: UIWindow) {
        var appOpenedCounter = persistence.appOpenedCounter

        if appOpenedCounter == 0 {
            persistence.appInstalledDate = Date()
        } else {
            let requestReviewDate = persistence.requestReviewDate

            if requestReviewDate == nil {
                let oldDate = persistence.appInstalledDate
                let today = Date()
                let difference = Calendar.current.dateComponents([.day], from: oldDate, to: today)

                if let daysCount = difference.day {
                    if daysCount >= 7, appOpenedCounter >= 10 {
                        requestReview(in: window)
                        persistence.requestReviewDate = Date()
                    }
                }
            }
        }

        appOpenedCounter += 1
        persistence.appOpenedCounter = appOpenedCounter
    }

    public func openAppReview() {
        let url = URL(validURL: "itms-apps://itunes.apple.com/app/id1118663303?action=write-review")
        application.open(url)
        analytics.review(automatic: false)
    }

    // MARK: Internal

    let analytics: AnalyticsLibrary
    let persistence = ReviewPersistence.shared
    let application: UIApplication = .shared

    // MARK: Private

    private func requestReview(in window: UIWindow) {
        guard let windowScene = window.windowScene else { return }
        SKStoreReviewController.requestReview(in: windowScene)
        analytics.review(automatic: true)
    }
}

private extension AnalyticsLibrary {
    func review(automatic: Bool) {
        logEvent("RequestReviewAutomatic", value: automatic.description)
    }
}
