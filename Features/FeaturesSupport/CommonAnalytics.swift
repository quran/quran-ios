//
//  CommonAnalytics.swift
//
//
//  Created by Mohamed Afifi on 2023-06-19.
//

import Analytics
import QuranKit

extension AnalyticsLibrary {
    public func removeBookmarkPage(_ page: Page) {
        logEvent("RemovePageBookmark", value: page.pageNumber.description)
    }

    public func openingQuran(from screen: Screen) {
        logEvent("OpeningQuranFrom", value: screen.rawValue)
    }
}
