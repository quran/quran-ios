//
//  AudioUpdate.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/15/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

struct AudioUpdates: Codable {
    let currentRevision: Int
    let updates: [Update]

    struct Update: Codable {
        let path: String
        let databaseVersion: Int?
        let files: [File]

        struct File: Codable {
            let filename: String
            let md5: String
        }
    }
}
