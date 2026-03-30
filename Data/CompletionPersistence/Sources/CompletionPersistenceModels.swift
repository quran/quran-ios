//
//  CompletionPersistenceModels.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Foundation

public struct CompletionPersistenceModel {
    public let id: UUID
    public let name: String?
    public let quranId: String
    public let startedAt: Date
    public let finishedAt: Date?
    public let isActive: Bool

    public init(id: UUID, name: String?, quranId: String, startedAt: Date, finishedAt: Date?, isActive: Bool) {
        self.id = id
        self.name = name
        self.quranId = quranId
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.isActive = isActive
    }
}

public struct CompletionBookmarkPersistenceModel {
    public let id: UUID
    public let completionId: UUID
    public let page: Int
    public let createdAt: Date

    public init(id: UUID, completionId: UUID, page: Int, createdAt: Date) {
        self.id = id
        self.completionId = completionId
        self.page = page
        self.createdAt = createdAt
    }
}
