//
//  MutatedPageBookmarkModel.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 10/02/2025.
//

import Foundation

/// Represents a page bookmark with mutation information.
///
/// This model is used to represent a bookmark that has been created or mutated locally. The model
/// may reference a remote bookmark that has been synced with the upstream server, in which case,
/// `remoteID` will be the ID of that bookmark. This means that the bookmark has been deleted
/// locally, but the deletion hasn't been marked as synced yet.
///
/// See `MutatedPageBookmarkPersistence` for more information regarding
/// the relationship between the local mutated bookmarks and the upstream-synced bookmarks.
public struct MutatedPageBookmarkModel {
    public enum Mutation {
        case created
        case deleted
    }

    /// If `nil`, then this is a local bookmark that hasn't been synced upstream. Otherwise, this
    /// is the remote ID of the upstream bookmark.
    public let remoteID: String?
    public let page: Int
    public let modificationDate: Date

    /// Represents the kind of mutation that casued this bookmark's current state.
    ///
    /// If `remoteID` is `nil`, then this will be `.created`. For remote bookmarks, this will be
    /// `.deleted`.
    public let mutation: Mutation
}
