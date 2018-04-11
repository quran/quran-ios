//
//  ReviewService.swift
//  Quran
//
//  Created by Muhammad Umer on 11/04/2018.
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

import Foundation
import StoreKit

struct ReviewService {
    private let simplePersistence: SimplePersistence

    init(simplePersistence: SimplePersistence) {
        self.simplePersistence = simplePersistence
    }

    func checkForReview() {
        var appOpenedCounter = simplePersistence.valueForKey(.appOpenedCounter)

        if appOpenedCounter == 0 {
            let date = Date().timeIntervalSince1970
            simplePersistence.setValue(date, forKey: .appInstalledDate)
        } else {
            let appInstalledDate = simplePersistence.valueForKey(.appInstalledDate)
            let oldDate = Date(timeIntervalSince1970: appInstalledDate)
            let today = Date()
            let difference = Calendar.current.dateComponents([.day, .minute], from: oldDate, to: today)

            if let daysCount = difference.day {
                if daysCount > 10 {
                    if appOpenedCounter > 7 {
                        requestReview()
                    }
                }
            }
        }

        appOpenedCounter += 1
        simplePersistence.setValue(appOpenedCounter, forKey: .appOpenedCounter)
    }

    private func requestReview() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
}
