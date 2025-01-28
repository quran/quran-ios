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

    public init(page: Page, creationDate: Date, remoteID: String? = nil) {
        self.page = page
        self.creationDate = creationDate
        self.remoteID = remoteID
    }

    // MARK: Public

    public let page: Page
    public let creationDate: Date
    public let remoteID: String?

    public var id: Page { page }
}
