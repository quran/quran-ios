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
        case color, createdOn, modifiedOn, page, remoteID
    }

    public enum LastPage: String, CoreDataKey {
        case createdOn, modifiedOn, page
    }
}
