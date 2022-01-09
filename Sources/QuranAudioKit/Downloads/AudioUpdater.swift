//
//  AudioUpdater.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/15/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Crashing
import Foundation
import PromiseKit
import VLogging

public protocol AudioUpdater {
    func updateAudioIfNeeded()
}

class DefaultAudioUpdater: AudioUpdater {
    private let recitersRetriever: ReciterDataRetriever
    private let networkService: AudioUpdatesNetworkManager
    private let preferences: AudioUpdatePreferences
    private let md5Calculator = MD5Calculator()

    init(networkService: AudioUpdatesNetworkManager,
         preferences: AudioUpdatePreferences,
         recitersRetriever: ReciterDataRetriever)
    {
        self.networkService = networkService
        self.preferences = preferences
        self.recitersRetriever = recitersRetriever
    }

    func updateAudioIfNeeded() {
        let fileManager = FileManager.default
        let audioFiles = FileManager.documentsURL.appendingPathComponent(Files.audioFilesPathComponent)
        let downloadedReciters = try? fileManager.contentsOfDirectory(at: audioFiles, includingPropertiesForKeys: nil)
        if downloadedReciters?.isEmpty ?? true {
            return
        }

        // update if 7 days passed since last checked
        let lastChecked = preferences.lastChecked
        if let lastChecked = lastChecked {
            let today = Date()
            let difference = Calendar.current.dateComponents([.day], from: lastChecked, to: today)
            if let day = difference.day, day < 7 {
                return
            }
        }

        let lastRevision = preferences.lastRevision

        logger.notice("Running AudioUpdater for revision \(lastRevision)")
        networkService
            .getAudioUpdates(revision: lastRevision)
            .get(on: .global()) { _ in self.updateLastChecked() }
            .then(update)
            .catch { error in
                crasher.recordError(error, reason: "Audio Update request failed.")
            }
    }

    private func updateLastChecked() {
        preferences.lastChecked = Date()
    }

    private func update(_ updates: AudioUpdates?) -> Guarantee<Void> {
        guard let updates = updates else {
            logger.notice("No new audio updates")
            return .value(())
        }
        return recitersRetriever.getReciters().map {
            self.update(reciters: $0, updates: updates)
        }
    }

    private func update(reciters: [Reciter], updates: AudioUpdates) {
        let reciters = Dictionary(uniqueKeysWithValues: reciters.map { ($0.audioURL.absoluteString.removingLastSlash, $0) })

        for update in updates.updates {
            guard let reciter = reciters[update.path.removingLastSlash] else {
                logger.warning("Couldn't find reciter with path: \(update.path)")
                continue
            }

            // not downloaded before
            if !reciter.localFolder().isReachable {
                continue
            }

            deleteDatabaseIfNeeded(for: reciter, update: update)

            for file in update.files {
                deleteFileIfNeeded(for: reciter, file: file)
            }
        }

        preferences.lastRevision = updates.currentRevision
    }

    private func deleteFileIfNeeded(for reciter: Reciter, file: AudioUpdates.Update.File) {
        let directory = reciter.localFolder()
        let localFile = directory.appendingPathComponent(file.filename)
        if !localFile.isReachable {
            return
        }
        let localMD5 = try? md5Calculator.stringMD5(for: localFile)
        if localMD5 == file.md5 {
            return
        }
        delete(localFile)
    }

    private func deleteDatabaseIfNeeded(for reciter: Reciter, update: AudioUpdates.Update) {
        guard case .gapless(let databaseName) = reciter.audioType else {
            return
        }
        let baseFileName = reciter.localFolder().appendingPathComponent(databaseName)
        let dbFile = baseFileName.appendingPathExtension(Files.databaseLocalFileExtension)
        let zipFile = baseFileName.appendingPathExtension(Files.databaseRemoteFileExtension)

        if !dbFile.isReachable {
            // in case we failed to unzip the file, it could contain an old version
            delete(zipFile)
            return
        }

        let persistence = SQLiteAyahTimingPersistence(filePath: dbFile)
        let version = try? persistence.getVersion()
        if version == update.databaseVersion {
            return
        }

        // delete the reciter timings database
        delete(dbFile)
        delete(zipFile)
    }

    private func delete(_ file: URL) {
        logger.notice("About to delete old audio file: \(file.absoluteString)")
        try? FileManager.default.removeItem(at: file)
    }
}

private extension String {
    var removingLastSlash: String {
        if hasSuffix("/") {
            return String(dropLast())
        }
        return self
    }
}
