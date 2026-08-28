//
//  ReciterWordSegmentRetrieverTests.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

import QuranAudio
import QuranKit
import TestResources
import XCTest
@testable import AudioTimingService

final class ReciterWordSegmentRetrieverTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try emptyReciterDirectory()
    }

    override func tearDown() async throws {
        try emptyReciterDirectory()
        try await super.tearDown()
    }

    func testReadsSegmentsFromTheReciterOwnDatabase() async throws {
        try installReciterDatabase(named: "word_segments.db")

        let timeline = try await retriever.wordSegments(for: gapless, sura: sura(1))

        XCTAssertEqual(timeline.segments.map(\.position), [1, 2, 3, 1])
        XCTAssertEqual(timeline.segment(atMillis: 1200)?.position, 1)
    }

    func testSuraTheDatabaseDoesNotCoverIsEmpty() async throws {
        try installReciterDatabase(named: "word_segments.db")

        let timeline = try await retriever.wordSegments(for: gapless, sura: sura(3))

        XCTAssertTrue(timeline.isEmpty)
    }

    /// The state of every published reciter database today.
    func testReciterDatabaseWithoutWordSegmentsIsEmpty() async throws {
        try installReciterDatabase(named: "reciter_without_segments.db")

        let timeline = try await retriever.wordSegments(for: gapless, sura: sura(1))

        XCTAssertTrue(timeline.isEmpty)
    }

    /// Gapped reciters have no timing database at all, so there is nothing to open.
    func testGappedReciterIsEmpty() async throws {
        let gapped = reciter(audioType: .gapped)

        let timeline = try await retriever.wordSegments(for: gapped, sura: sura(1))

        XCTAssertTrue(timeline.isEmpty)
    }

    // MARK: Private

    private let retriever = ReciterWordSegmentRetriever()
    private let quran = Quran.hafsMadani1405

    /// Unique per test: `DatabaseConnection` pools connections globally by URL, so a path
    /// reused with different contents would serve the previous test's database.
    private let reciterDirectory = "test_reciter_\(UUID().uuidString)"

    private var gapless: Reciter {
        reciter(audioType: .gapless(databaseName: reciterDirectory))
    }

    private func sura(_ number: Int) -> Sura {
        Sura(quran: quran, suraNumber: number)!
    }

    private func reciter(audioType: AudioType) -> Reciter {
        Reciter(
            id: 1,
            nameKey: reciterDirectory,
            directory: reciterDirectory,
            audioURL: URL(string: "https://example.com/audio/")!,
            audioType: audioType,
            hasGaplessAlternative: false,
            category: .arabic
        )
    }

    /// Puts a fixture where the app would have unzipped the downloaded database, so the
    /// production `Reciter.localDatabasePath` mapping is what the test exercises.
    private func installReciterDatabase(named fixture: String) throws {
        let destination = try emptyReciterDirectory()
        try FileManager.default.copyItem(at: TestResources.resourceURL(fixture), to: destination)
    }

    /// Clears the whole directory, so SQLite's -wal and -shm siblings cannot outlive a
    /// fixture and corrupt the next one.
    @discardableResult
    private func emptyReciterDirectory() throws -> URL {
        let destination = try XCTUnwrap(gapless.localDatabasePath).url
        let directory = destination.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return destination
    }
}
