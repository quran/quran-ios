//
//  Reciter+Preparation.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
import QuranAudio
import TestResources
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

    public var gaplessDatabaseZipURL: URL {
        localFolder().appendingPathComponent(gaplessDatabaseZip)
    }

    public var gaplessDatabaseURL: URL {
        localFolder().appendingPathComponent(gaplessDatabaseDB)
    }

    public func prepareGaplessReciterForTests(unZip: Bool = false) throws {
        let directory = localFolder()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let dbSource = resource(gaplessDatabaseZip)
        let zipDestination = gaplessDatabaseZipURL
        try FileManager.default.copyItem(at: dbSource, to: gaplessDatabaseZipURL)
        if unZip {
            try Zip.unzipFile(zipDestination, destination: directory, overwrite: true, password: nil, progress: nil)
        }
    }

    public static func cleanUpAudio() {
        try? FileManager.default.removeItem(at: audioFiles)
    }

    private func resource(_ path: String) -> URL {
        TestResources.resourceURL(path)
    }
}
