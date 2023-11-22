//
//  Reciter+Preparation.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
import QuranAudio
import SystemDependencies
import TestResources
import Utilities
import Zip

extension Reciter {
    public var gaplessDatabaseZip: String {
        guard case .gapless(databaseName: let databaseName) = audioType else { fatalError() }
        return databaseName + ".zip"
    }

    public var gaplessDatabaseDB: String {
        guard case .gapless(databaseName: let databaseName) = audioType else { fatalError() }
        return databaseName + ".db"
    }

    public var gaplessDatabaseZipPath: RelativeFilePath {
        localFolder().appendingPathComponent(gaplessDatabaseZip, isDirectory: false)
    }

    public var gaplessDatabasePath: RelativeFilePath {
        localFolder().appendingPathComponent(gaplessDatabaseDB, isDirectory: false)
    }

    public func prepareGaplessReciterForTests(unZip: Bool = false) throws {
        let directory = localFolder()
        try DefaultFileSystem().createDirectory(at: directory, withIntermediateDirectories: true)
        let dbSource = resource(gaplessDatabaseZip)
        let zipDestination = gaplessDatabaseZipPath
        try FileManager.default.copyItem(at: dbSource, to: gaplessDatabaseZipPath)
        if unZip {
            try Zip.unzipFile(zipDestination.url, destination: directory.url, overwrite: true, password: nil, progress: nil)
        }
    }

    public static func cleanUpAudio() {
        try? FileManager.default.removeItem(at: audioFiles)
    }

    private func resource(_ path: String) -> URL {
        TestResources.resourceURL(path)
    }
}
