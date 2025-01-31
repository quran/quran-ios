//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 31/01/2025.
//

import Foundation
import Combine
import GRDB
import VLogging
import SQLitePersistence

public struct GRDBPageBookmarkPersistence: PageBookmarkPersistence {
    private let db: DatabaseConnection

    init(db: DatabaseConnection) {
        self.db = db
    }

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        CurrentValueSubject([]).eraseToAnyPublisher()
    }
    
    public func insertPageBookmark(_ page: Int) async throws {

    }
    
    public func removePageBookmark(_ page: Int) async throws {
        
    }
}
