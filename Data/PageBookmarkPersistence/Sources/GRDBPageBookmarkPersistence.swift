//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 31/01/2025.
//

import Foundation
import Combine
import GRDB

public struct GRDBPAgeBookmarkPersistence: PageBookmarkPersistence {
    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        <#code#>
    }
    
    public func insertPageBookmark(_ page: Int) async throws {
        <#code#>
    }
    
    public func removePageBookmark(_ page: Int) async throws {
        <#code#>
    }
}
