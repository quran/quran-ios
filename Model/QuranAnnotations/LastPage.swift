//
//  LastPage.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/5/16.
//

import Foundation
import QuranKit

public struct LastPage: Equatable, Identifiable, Sendable {
    // MARK: Lifecycle

    #if QURAN_SYNC
    public init(id: String, page: Page, modifiedOn: Date) {
        self.id = id
        self.page = page
        self.modifiedOn = modifiedOn
    }
    #else
    public init(page: Page, createdOn: Date, modifiedOn: Date) {
        self.page = page
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    #endif

    // MARK: Public

    #if QURAN_SYNC
    public let id: String
    #else
    public var id: Page { page }
    public var createdOn: Date
    #endif

    public var page: Page
    public var modifiedOn: Date
}
