//
//  AudioUpdaterTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

@testable import BatchDownloader
import Foundation
@testable import QuranAudioKit
import TestUtilities
import XCTest

class AudioUpdaterTests: XCTestCase {
    private var updater: AudioUpdater!
    private var session: NetworkSessionFake!
    private var fileSystem: FileSystemFake!
    private var time: SystemTimeFake!
    private var bundle: SystemBundleFake!
    private var preferences = AudioUpdatePreferences.shared

    private let baseURL = URL(validURL: "http://example.com")
    private let audioFiles = FileManager.documentsURL.appendingPathComponent(Files.audioFilesPathComponent)

    private static let reciter = Reciter.gaplessReciter
    private let zipFile = reciter.localFolder().appendingPathComponent(Reciter.gaplessDatabaseName + ".zip")
    private static let file = "1.mp3"
    private let fileURL = reciter.localFolder().appendingPathComponent(file)
    private let recitersPlist = "reciters.plist"

    override func setUpWithError() throws {
        preferences.reset()

        session = NetworkSessionFake(queue: .main, delegate: nil)
        fileSystem = FileSystemFake()
        time = SystemTimeFake()
        bundle = SystemBundleFake()

        let networkManager = NetworkManager(session: session, baseURL: baseURL)
        updater = AudioUpdater(networkManager: networkManager,
                               recitersRetriever: ReciterDataRetriever(bundle: bundle),
                               fileSystem: fileSystem,
                               time: time)

        // Prepare data

        let reciters: [Reciter] = [.gaplessReciter, .gappedReciter]
        fileSystem.filesInDirectory[audioFiles] = reciters.map { URL(fileURLWithPath: $0.directory) }
        fileSystem.files = [Self.reciter.localFolder(), fileURL]

        let rawReciters = reciters.map { reciter in
            [
                "id": reciter.id,
                "name": reciter.nameKey,
                "path": reciter.directory,
                "url": reciter.audioURL.absoluteString,
                "databaseName": reciter == .gaplessReciter ? Reciter.gaplessDatabaseName : "",
                "hasGaplessAlternative": reciter.hasGaplessAlternative,
                "category": reciter.category.rawValue,
            ] as [String: Any]
        }
        bundle.arrays = [recitersPlist: rawReciters as NSArray]
    }

    func test_updateAudioIfNeeded_noDownloads() async {
        fileSystem.filesInDirectory = [:]

        await updater.updateAudioIfNeeded()
        XCTAssertEqual(fileSystem.removedItems, [])
        XCTAssertNil(preferences.lastChecked)
        XCTAssertEqual(preferences.lastRevision, 0)
    }

    func test_updateAudioIfNeeded_noUpdates() async throws {
        let now = Date(timeIntervalSince1970: 0)
        time.now = now

        let updates = AudioUpdates(currentRevision: 45, updates: [])
        try nextUpdates(updates)

        await updater.updateAudioIfNeeded()

        XCTAssertEqual(Set(fileSystem.removedItems), [])
        XCTAssertEqual(preferences.lastRevision, 45)
    }

    func test_updateAudioIfNeeded_removeItems() async throws {
        let now = Date(timeIntervalSince1970: 0)
        time.now = now

        let update = AudioUpdates.Update(path: Self.reciter.audioURL.absoluteString,
                                         databaseVersion: nil,
                                         files: [AudioUpdates.Update.File(filename: Self.file, md5: "")])
        let updates = AudioUpdates(currentRevision: 45, updates: [update])
        try nextUpdates(updates)

        await updater.updateAudioIfNeeded()

        XCTAssertEqual(Set(fileSystem.removedItems), [fileURL, zipFile])
        XCTAssertEqual(preferences.lastRevision, updates.currentRevision)
        XCTAssertEqual(preferences.lastChecked, time.now)

        let nextUpdate = AudioUpdates(currentRevision: updates.currentRevision + 1, updates: [update])

        // Try again same day
        time.now = Date(timeInterval: 60 * 60, since: now)
        try nextUpdates(nextUpdate)

        await updater.updateAudioIfNeeded()
        XCTAssertEqual(preferences.lastRevision, updates.currentRevision)

        // Try again after 7 days
        time.now = Date(timeInterval: 60 * 60 * 24 * 7 + 1, since: now)
        try nextUpdates(nextUpdate)

        await updater.updateAudioIfNeeded()
        XCTAssertEqual(preferences.lastRevision, nextUpdate.currentRevision)
        XCTAssertEqual(preferences.lastChecked, time.now)
    }

    private func nextUpdates(_ updates: AudioUpdates) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let request = NetworkManager.request(baseURL: baseURL,
                                             path: "/data/audio_updates.php",
                                             parameters: [("revision", preferences.lastRevision.description)])
        session.dataResults[request.url!] = .success(try encoder.encode(updates))
    }
}
