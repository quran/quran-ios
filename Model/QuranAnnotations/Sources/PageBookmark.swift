//
//  PageBookmark.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//

import Foundation
import QuranKit

public struct PageBookmark: Equatable, Identifiable {
    // MARK: Lifecycle

    public init(page: Page, creationDate: Date) {
        self.init(
            page: page,
            storedPages: [page],
            creationDate: creationDate
        )
    }

    public init(page: Page, storedPages: Set<Page>, creationDate: Date) {
        self.page = page
        self.storedPages = storedPages
        self.creationDate = creationDate
    }

    // MARK: Public

    public let page: Page
    public let storedPages: Set<Page>
    public let creationDate: Date

    public var id: Page { page }
}
