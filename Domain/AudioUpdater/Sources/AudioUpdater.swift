//
//  AudioUpdater.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/15/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AudioTimingPersistence
import Crashing
import Foundation
import NetworkSupport
import QuranAudio
import ReciterService
import SystemDependencies
import VLogging

public final class AudioUpdater {
    private let recitersRetriever: ReciterDataRetriever
    private let networkService: AudioUpdatesNetworkManager
    private let preferences = AudioUpdatePreferences.shared
    private let md5Calculator = MD5Calculator()
    private let fileSystem: FileSystem
    private let time: SystemTime

    init(
        networkManager: NetworkManager,
        recitersRetriever: ReciterDataRetriever,
        fileSystem: FileSystem,
        time: SystemTime
    ) {
        networkService = AudioUpdatesNetworkManager(networkManager: networkManager)
        self.recitersRetriever = recitersRetriever
        self.fileSystem = fileSystem
        self.time = time
    }

    public init(baseURL: URL) {
        let networkManager = NetworkManager(baseURL: baseURL)
        networkService = AudioUpdatesNetworkManager(networkManager: networkManager)
        recitersRetriever = ReciterDataRetriever()
        fileSystem = DefaultFileSystem()
        time = DefaultSystemTime()
    }

    public func updateAudioIfNeeded() async {
        let downloadedReciters = try? fileSystem.contentsOfDirectory(at: Reciter.audioFiles, includingPropertiesForKeys: nil)
        if downloadedReciters?.isEmpty ?? true {
            return
        }

        // update if 7 days passed since last checked
        let lastChecked = preferences.lastChecked
        if let lastChecked {
            let today = time.now
            let difference = Calendar.current.dateComponents([.day], from: lastChecked, to: today)
            if let day = difference.day, day < 7 {
                return
            }
        }

        let lastRevision = preferences.lastRevision

        logger.notice("Running AudioUpdater for revision \(lastRevision)")
        do {
            let updates = try await networkService.getAudioUpdates(revision: lastRevision)
            updateLastChecked()
            await update(updates)
        } catch {
            crasher.recordError(error, reason: "Audio Update request failed.")
        }
    }

    private func updateLastChecked() {
        preferences.lastChecked = time.now
    }

    private func update(_ updates: AudioUpdates?) async {
        guard let updates else {
            logger.notice("No new audio updates")
            return
        }
        let reciters = await recitersRetriever.getReciters()
        await update(reciters: reciters, updates: updates)
    }

    private func update(reciters: [Reciter], updates: AudioUpdates) async {
        let reciters = Dictionary(uniqueKeysWithValues: reciters.map { ($0.audioURL.absoluteString.removingLastSlash, $0) })

        for update in updates.updates {
            guard let reciter = reciters[update.path.removingLastSlash] else {
                logger.warning("Couldn't find reciter with path: \(update.path)")
                continue
            }

            // not downloaded before
            if !fileSystem.fileExists(at: reciter.localFolder()) {
                continue
            }

            await deleteDatabaseIfNeeded(for: reciter, update: update)

            for file in update.files {
                deleteFileIfNeeded(for: reciter, file: file)
            }
        }

        preferences.lastRevision = updates.currentRevision
    }

    private func deleteFileIfNeeded(for reciter: Reciter, file: AudioUpdates.Update.File) {
        let directory = reciter.localFolder()
        let localFile = directory.appendingPathComponent(file.filename)
        if !fileSystem.fileExists(at: localFile) {
            return
        }
        let localMD5 = try? md5Calculator.stringMD5(for: localFile)
        if localMD5 == file.md5 {
            return
        }
        delete(localFile)
    }

    private func deleteDatabaseIfNeeded(for reciter: Reciter, update: AudioUpdates.Update) async {
        guard let dbFile = reciter.localDatabaseURL, let zipFile = reciter.localZipURL else {
            return
        }

        if !fileSystem.fileExists(at: dbFile) {
            // in case we failed to unzip the file, it could contain an old version
            delete(zipFile)
            return
        }

        if await getDatabaseVersion(fileURL: dbFile) == update.databaseVersion {
            return
        }

        // delete the reciter timings database
        delete(dbFile)
        delete(zipFile)
    }

    private func getDatabaseVersion(fileURL: URL) async -> Int? {
        do {
            let persistence = GRDBAyahTimingPersistence(fileURL: fileURL)
            return try await persistence.getVersion()
        } catch {
            logger.error("Error accessing the timing database. Error: \(error)")
            return nil
        }
    }

    private func delete(_ file: URL) {
        logger.notice("About to delete old audio file: \(file.absoluteString)")
        try? fileSystem.removeItem(at: file)
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
