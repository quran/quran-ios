//
//  FileSystemFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
@testable import QuranAudioKit

final class FileSystemFake: FileSystem {
    var files: Set<URL> = []
    var checkedFiles: Set<URL> = []

    func fileExists(at url: URL) -> Bool {
        checkedFiles.insert(url)
        return files.contains(url)
    }

    var removedItems: [URL] = []
    func removeItem(at url: URL) throws {
        removedItems.append(url)
    }

    var filesInDirectory: [URL: [URL]] = [:]
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        filesInDirectory[url] ?? []
    }
}
