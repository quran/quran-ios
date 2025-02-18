//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 18/02/2025.
//

import Foundation
import Combine

// TODO: Might need to rename this.
public final class SynchronizedPageBookmarkPersistence: PageBookmarkPersistence {
    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        fatalError()
    }
    
    public func insertPageBookmark(_ page: Int) async throws {
        fatalError()
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        fatalError()
    }
}
