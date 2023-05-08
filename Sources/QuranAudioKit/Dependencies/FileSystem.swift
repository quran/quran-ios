//
//  FileSystem.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation

protocol FileSystem {
    func fileExists(at url: URL) -> Bool
    func removeItem(at url: URL) throws
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL]
}

struct DefaultFileSystem: FileSystem {
    func fileExists(at url: URL) -> Bool {
        url.isReachable
    }

    func removeItem(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
}
