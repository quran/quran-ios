//
//  CompletionModels.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Foundation
import QuranKit

public struct Completion: Equatable, Identifiable {
    public let id: UUID
    public var name: String?
    public let quran: Quran
    public let startedAt: Date
    public var finishedAt: Date?
    public var isActive: Bool

    public init(id: UUID, name: String?, quran: Quran, startedAt: Date, finishedAt: Date?, isActive: Bool) {
        self.id = id
        self.name = name
        self.quran = quran
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.isActive = isActive
    }

    public static func == (lhs: Completion, rhs: Completion) -> Bool {
        lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.quran == rhs.quran &&
            lhs.startedAt == rhs.startedAt &&
            lhs.finishedAt == rhs.finishedAt &&
            lhs.isActive == rhs.isActive
    }
}

public struct CompletionBookmark: Equatable, Identifiable {
    public let id: UUID
    public let completionId: UUID
    public let page: Page
    public let createdAt: Date

    public init(id: UUID, completionId: UUID, page: Page, createdAt: Date) {
        self.id = id
        self.completionId = completionId
        self.page = page
        self.createdAt = createdAt
    }
}

public struct CompletionProgress {
    public let completion: Completion
    public let totalPages: Int
    public let currentPage: Page?
    public let pagesRead: Int
    public var averageTimePerPage: TimeInterval?
    public var estimatedFinishDate: Date?

    public var pagesRemaining: Int { totalPages - pagesRead }
    public var percentComplete: Double { Double(pagesRead) / Double(totalPages) }

    public init(
        completion: Completion,
        totalPages: Int,
        currentPage: Page?,
        pagesRead: Int,
        averageTimePerPage: TimeInterval?,
        estimatedFinishDate: Date?
    ) {
        self.completion = completion
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.pagesRead = pagesRead
        self.averageTimePerPage = averageTimePerPage
        self.estimatedFinishDate = estimatedFinishDate
    }
}
