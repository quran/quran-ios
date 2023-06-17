//
//  PageBookmark.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//

import Foundation
import QuranKit

public struct PageBookmark: Equatable {
    // MARK: Lifecycle

    public init(page: Page, creationDate: Date) {
        self.page = page
        self.creationDate = creationDate
    }

    // MARK: Public

    public let page: Page
    public let creationDate: Date
}
