//
//  SyncedPageBookmarkPersistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 09/02/2025.
//

import Combine
import Foundation

public protocol SyncedPageBookmarkPersistence {
    func pageBookmarksPublisher() throws -> AnyPublisher<[SyncedPageBookmarkPersistenceModel], Never>
    func bookmark(page: Int) async throws -> SyncedPageBookmarkPersistenceModel?
    func insertBookmark(_ bookmark: SyncedPageBookmarkPersistenceModel) async throws
    func removeBookmark(withRemoteID remoteID: String) async throws
}
