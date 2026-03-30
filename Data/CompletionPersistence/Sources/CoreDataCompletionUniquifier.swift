//
//  CoreDataCompletionUniquifier.swift
//
//
//  Created by Selim on 29.03.2026.
//

import CoreDataModel
import CoreDataPersistence

public typealias CoreDataCompletionUniquifier = SimpleCoreDataEntityUniquifier<MO_Completion>
extension CoreDataCompletionUniquifier {
    public init() {
        self.init(sortBy: Schema.Completion.startedAt, ascending: false, key: .id)
    }
}

public typealias CoreDataCompletionBookmarkUniquifier = SimpleCoreDataEntityUniquifier<MO_CompletionBookmark>
extension CoreDataCompletionBookmarkUniquifier {
    public init() {
        self.init(sortBy: Schema.CompletionBookmark.createdAt, ascending: false, key: .id)
    }
}
