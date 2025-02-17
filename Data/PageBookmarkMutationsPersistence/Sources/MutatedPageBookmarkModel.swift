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

    let remoteID: String?
    let page: Int
    let modificationDate: Date
    let mutation: Mutation
}
