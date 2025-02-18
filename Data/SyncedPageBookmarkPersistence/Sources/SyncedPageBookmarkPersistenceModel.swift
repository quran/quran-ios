//
//  SyncedPageBookmarkPersistenceModel.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 09/02/2025.
//

import Foundation

public struct SyncedPageBookmarkPersistenceModel {
    public let page: Int
    public let remoteID: String
    public let creationDate: Date

    public init(page: Int, remoteID: String, creationDate: Date) {
        self.page = page
        self.remoteID = remoteID
        self.creationDate = creationDate
    }
}
