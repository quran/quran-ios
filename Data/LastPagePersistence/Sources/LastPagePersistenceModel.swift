//
//  LastPagePersistenceModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-03-05.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import Foundation
import QuranKit

public struct LastPagePersistenceModel {
    // MARK: Lifecycle

    public init(
        page: Page,
        createdOn: Date,
        modifiedOn: Date
    ) {
        self.page = page
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }

    // MARK: Public

    public let page: Page
    public let createdOn: Date
    public let modifiedOn: Date
}
