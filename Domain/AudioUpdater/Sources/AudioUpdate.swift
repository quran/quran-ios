//
//  AudioUpdate.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/15/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

struct AudioUpdates: Codable {
    struct Update: Codable {
        struct File: Codable {
            let filename: String
            let md5: String
        }

        // MARK: Internal

        let path: String
        let databaseVersion: Int?
        let files: [File]
    }

    // MARK: Internal

    let currentRevision: Int
    let updates: [Update]
}
