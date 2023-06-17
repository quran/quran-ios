//
//  AudioUpdaterTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation
import NetworkSupportFake
import ReciterServiceFake
import SystemDependenciesFake
import XCTest
@testable import AudioUpdater
@testable import NetworkSupport
@testable import QuranAudio
@testable import ReciterService

class AudioUpdaterTests: XCTestCase {
    private var updater: AudioUpdater!
    private var session: NetworkSessionFake!
    private var fileSystem: FileSystemFake!
    private var time: SystemTimeFake!
    private var bundle: SystemBundleFake!
    private var preferences = AudioUpdatePreferences.shared

    private let now = Date(timeIntervalSince1970: 0)

    private let reciters: [Reciter] = [.gaplessReciter, .gappedReciter]
    private let gappedReciter: Reciter = .gappedReciter
    private let gaplessReciter: Reciter = .gaplessReciter

    private let baseURL = URL(validURL: "http://example.com")
    private let file1 = "1.mp3"
    private let file2 = "2.mp3"

    override func setUp() async throws {
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
        setUpReciters()
        setUpFileSystem()
        time.now = now
    }

    override func tearDown() async throws {
        Reciter.cleanUpAudio()
    }

    private func setUpReciters() {
        let recitersPlist = "reciters.plist"
        bundle.arrays = [recitersPlist: reciters.map { $0.toPlistDictionary() } as NSArray]
    }

    private func setUpFileSystem() {
        fileSystem.filesInDirectory[Reciter.audioFiles] = reciters.map { URL(fileURLWithPath: $0.directory) }
        fileSystem.files = Set(reciters.flatMap { reciter in
            [
                reciter.localFolder(),
                reciter.localFolder().appendingPathComponent(file1),
                reciter.localFolder().appendingPathComponent(file1),
                reciter.localFolder().appendingPathComponent(file2),
            ]
        })
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

    func test_updateAudioIfNeeded_gapped_removeFiles() async throws {
        let update = makeUpdate(reciter: gappedReciter, files: [file1, file2])
        let updates = AudioUpdates(currentRevision: 1945, updates: [update])
        try nextUpdates(updates)

        await updater.updateAudioIfNeeded()

        XCTAssertEqual(Set(fileSystem.removedItems), [
            gappedReciter.localFolder().appendingPathComponent(file1),
            gappedReciter.localFolder().appendingPathComponent(file2),
        ])
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

    func test_updateAudioIfNeeded_gapless_removeFileAndZip() async throws {
        let update = makeUpdate(reciter: gaplessReciter, files: [file1])
        let updates = AudioUpdates(currentRevision: 45, updates: [update])
        try nextUpdates(updates)

        await updater.updateAudioIfNeeded()

        XCTAssertEqual(Set(fileSystem.removedItems), [
            gaplessReciter.gaplessDatabaseZipURL,
            gaplessReciter.localFolder().appendingPathComponent(file1),
        ])
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

    func test_updateAudioIfNeeded_gapless_removeDatabase() async throws {
        try gaplessReciter.prepareGaplessReciterForTests(unZip: true)

        fileSystem.files.insert(gaplessReciter.gaplessDatabaseURL)

        let update = makeUpdate(reciter: gaplessReciter, databaseVersion: 100, files: [])
        let updates = AudioUpdates(currentRevision: 19, updates: [update])
        try nextUpdates(updates)

        await updater.updateAudioIfNeeded()

        XCTAssertEqual(Set(fileSystem.removedItems), [
            gaplessReciter.gaplessDatabaseZipURL,
            gaplessReciter.gaplessDatabaseURL,
        ])
        XCTAssertEqual(preferences.lastRevision, updates.currentRevision)
        XCTAssertEqual(preferences.lastChecked, time.now)
    }

    func test_updateAudioIfNeeded_gapless_upToDateDatabase() async throws {
        try gaplessReciter.prepareGaplessReciterForTests(unZip: true)
        fileSystem.files.insert(gaplessReciter.gaplessDatabaseURL)

        let update = makeUpdate(reciter: gaplessReciter, databaseVersion: 6, files: [])
        let updates = AudioUpdates(currentRevision: 19, updates: [update])
        try nextUpdates(updates)

        await updater.updateAudioIfNeeded()

        XCTAssertEqual(Set(fileSystem.removedItems), [])
        XCTAssertEqual(preferences.lastRevision, updates.currentRevision)
        XCTAssertEqual(preferences.lastChecked, time.now)
    }

    private func makeUpdate(reciter: Reciter, databaseVersion: Int? = nil, files: [String]) -> AudioUpdates.Update {
        AudioUpdates.Update(path: reciter.audioURL.absoluteString,
                            databaseVersion: databaseVersion,
                            files: files.map { AudioUpdates.Update.File(filename: $0, md5: "") })
    }

    private func nextUpdates(_ updates: AudioUpdates) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let parameters = [(AudioUpdatesNetworkManager.revision, preferences.lastRevision.description)]
        let request = NetworkManager.request(baseURL: baseURL,
                                             path: AudioUpdatesNetworkManager.path,
                                             parameters: parameters)
        session.dataResults[request.url!] = .success(try encoder.encode(updates))
    }
}
