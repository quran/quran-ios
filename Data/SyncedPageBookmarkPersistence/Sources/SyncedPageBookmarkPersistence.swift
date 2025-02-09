//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 09/02/2025.
//

import Foundation
import Combine

public protocol SyncedPageBookmarkPersistence {
    func pageBookmarksPublisher() throws -> AnyPublisher<[SyncedPageBookmarkPersistenceModel], Never> 
    func insert(bookmark: SyncedPageBookmarkPersistenceModel) async throws
    func removeBookmark(withRemoteID remoteID: SyncedPageBookmarkPersistenceModel) async throws
}
