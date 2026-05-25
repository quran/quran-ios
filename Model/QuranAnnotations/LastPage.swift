//
//  LastPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/5/16.
//

import Foundation
import QuranKit

public struct LastPage: Equatable, Identifiable {
    // MARK: Lifecycle

    public init(page: Page, createdOn: Date, modifiedOn: Date, localId: String? = nil) {
        self.page = page
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
        self.localId = localId
    }

    // MARK: Public

    public var page: Page
    public var createdOn: Date
    public var modifiedOn: Date
    public var localId: String?

    public var id: Page { page }
}
