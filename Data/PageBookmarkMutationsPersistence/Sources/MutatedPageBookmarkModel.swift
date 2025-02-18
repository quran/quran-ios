//
//  MutatedPageBookmarkModel.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 10/02/2025.
//

import Foundation

public struct MutatedPageBookmarkModel {
    public enum Mutation {
        case created
        case deleted
    }

    public let remoteID: String?
    public let page: Int
    public let modificationDate: Date
    public let mutation: Mutation
}
