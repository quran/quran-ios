//
//  Reciter+Preparation.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
@testable import QuranAudioKit
import Zip

extension Reciter {
    var gaplessDatabaseZip: String {
        guard case .gapless(databaseName: let databaseName) = audioType else { fatalError() }
        return databaseName + ".zip"
    }

    var gaplessDatabaseDB: String {
        guard case .gapless(databaseName: let databaseName) = audioType else { fatalError() }
        return databaseName + ".db"
    }

    var gaplessDatabaseZipURL: URL {
        localFolder().appendingPathComponent(gaplessDatabaseZip)
    }

    var gaplessDatabaseURL: URL {
        localFolder().appendingPathComponent(gaplessDatabaseDB)
    }

    func prepareGaplessReciterForTests(unZip: Bool = false) throws {
        let directory = localFolder()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let dbSource = resource(gaplessDatabaseZip)
        let zipDestination = gaplessDatabaseZipURL
        try FileManager.default.copyItem(at: dbSource, to: gaplessDatabaseZipURL)
        if unZip {
            try Zip.unzipFile(zipDestination, destination: directory, overwrite: true, password: nil, progress: nil)
        }
    }

    static func cleanUpAudio() {
        try? FileManager.default.removeItem(at: audioFiles)
    }

    private func resource(_ path: String) -> URL {
        Bundle.module.url(forResource: "test_data/" + path, withExtension: nil)!
    }
}
