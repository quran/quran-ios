//
//  Schema.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreDataPersistence

public enum Schema {
    public enum Note: String, CoreDataKey {
        case color, createdOn, modifiedOn, note, verses
    }

    public enum Verse: String, CoreDataKey {
        case ayah, sura, note
    }

    public enum PageBookmark: String, CoreDataKey {
        case color, createdOn, modifiedOn, page
    }

    public enum LastPage: String, CoreDataKey {
        case createdOn, modifiedOn, page
    }

    public enum Completion: String, CoreDataKey {
        case id, name, quranId, startedAt, finishedAt, isActive
    }

    public enum CompletionBookmark: String, CoreDataKey {
        case id, completionId, page, createdAt
    }
}
