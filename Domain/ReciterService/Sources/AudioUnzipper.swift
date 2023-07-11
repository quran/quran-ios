//
//  AudioUnzipper.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Crashing
import Foundation
import QuranAudio
import VLogging
import Zip

public struct AudioUnzipper {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func unzip(reciter: Reciter) async throws {
        guard let dbFile = reciter.localDatabasePath?.url, let zipFile = reciter.localZipPath?.url else {
            return
        }

        guard !dbFile.isReachable else {
            return
        }

        logger.info("Unzipping audio file. Reciter=\(reciter.nameKey) file=\(zipFile).")
        do {
            try Zip.unzipFile(zipFile, destination: reciter.localFolder().url, overwrite: true, password: nil, progress: nil)
        } catch {
            crasher.recordError(error, reason: "Cannot unzip file '\(zipFile)' to '\(reciter.localFolder())'")
            // delete the zip and try to re-download it again, next time.
            try? FileManager.default.removeItem(at: zipFile)
            throw error
        }
    }
}
