//
//  AudioUnzipper.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Crashing
import Foundation
import PromiseKit
import Zip

class AudioUnzipper {
    func unzip(reciter: Reciter) -> Guarantee<Void> {
        guard case .gapless(let databaseName) = reciter.audioType else {
            return Guarantee.value(())
        }
        let baseFileName = reciter.localFolder().appendingPathComponent(databaseName)
        let dbFile = baseFileName.appendingPathExtension(Files.databaseLocalFileExtension)
        let zipFile = baseFileName.appendingPathExtension(Files.databaseRemoteFileExtension)

        guard !dbFile.isReachable else {
            return Guarantee.value(())
        }

        return DispatchQueue.global().async(.guarantee) {
            do {
                try Zip.unzipFile(zipFile, destination: reciter.localFolder(), overwrite: true, password: nil, progress: nil)
            } catch {
                crasher.recordError(error, reason: "Cannot unzip file '\(zipFile)' to '\(reciter.localFolder())'")
                // delete the zip and try to re-download it again, next time.
                try? FileManager.default.removeItem(at: zipFile)
            }
        }
    }
}
