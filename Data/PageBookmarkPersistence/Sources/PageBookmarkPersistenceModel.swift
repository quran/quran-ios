//
//  PageBookmarkPersistenceModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation
import QuranKit

public struct PageBookmarkPersistenceModel {
    // MARK: Lifecycle

    public init(page: Page, creationDate: Date) {
        self.page = page
        self.creationDate = creationDate
    }

    // MARK: Public

    public let page: Page
    public let creationDate: Date
}
