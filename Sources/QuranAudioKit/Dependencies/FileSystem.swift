//
//  FileSystem.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation

protocol FileSystem {
    func fileExists(at url: URL) -> Bool
}

struct DefaultFileSystem: FileSystem {
    func fileExists(at url: URL) -> Bool {
        url.isReachable
    }
}
