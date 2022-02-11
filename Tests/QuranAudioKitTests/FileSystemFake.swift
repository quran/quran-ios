//
//  FileSystemFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
@testable import QuranAudioKit

class FileSystemFake: FileSystem {
    var files: Set<URL> = []
    var checkedFiles: Set<URL> = []

    func fileExists(at url: URL) -> Bool {
        checkedFiles.insert(url)
        return files.contains(url)
    }
}
