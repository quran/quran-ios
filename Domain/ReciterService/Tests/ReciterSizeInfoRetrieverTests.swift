//
//  ReciterSizeInfoRetrieverTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-14.
//

import QuranKit
import ReciterServiceFake
import SystemDependenciesFake
import XCTest
@testable import QuranAudio
@testable import ReciterService

class ReciterSizeInfoRetrieverTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        fileSystem = FileSystemFake()
        service = ReciterSizeInfoRetriever(baseURL: baseURL, fileSystem: fileSystem)
    }

    // MARK: - No Download

    func test_bothRecitersInitiallyNoDownloads() async throws {
        try await runNoDownloadsTest([gappedReciter, gaplessReciter])
    }

    func test_gappedInitiallyNoDownloads() async throws {
        try await runNoDownloadsTest([gappedReciter])
    }

    func test_gaplessInitiallyNoDownloads() async throws {
        try await runNoDownloadsTest([gaplessReciter])
    }

    // MARK: - Fully Downloaded

    func test_gappedFullyDownloaded() async throws {
        try await runFullDownloadedTest([gappedReciter])
    }

    func test_gaplessFullyDownloaded() async throws {
        try await runFullDownloadedTest([gaplessReciter])
    }

    func test_bothRecitersFullyDownloaded() async throws {
        try await runFullDownloadedTest([gaplessReciter, gappedReciter])
    }

    // MARK: - Partial Downloaded Gapped

    func test_gappedSingleSuraDownloaded() async throws {
        let firstSuraAyahs = quran.suras[0].verses
        try await runPartialDownloadedGappedTest(
            ayahs: firstSuraAyahs,
            downloadedSuraCount: 1
        )
        try await runPartialDownloadedGappedTest(
            ayahs: firstSuraAyahs.dropLast(),
            downloadedSuraCount: 0
        )
    }

    // MARK: - Partial Downloaded Gapless

    func test_gaplessSingleSuraDownloaded() async throws {
        try await runPartialDownloadedGaplessTest(
            suras: [quran.suras[0]],
            dbDownloaded: true,
            downloadedSuraCount: 1
        )
        try await runPartialDownloadedGaplessTest(
            suras: [quran.suras[0]],
            dbDownloaded: false,
            downloadedSuraCount: 1
        )
        try await runPartialDownloadedGaplessTest(
            suras: [],
            dbDownloaded: true,
            downloadedSuraCount: 0
        )
        try await runPartialDownloadedGaplessTest(
            suras: quran.suras,
            dbDownloaded: true,
            downloadedSuraCount: quran.suras.count
        )
    }

    // MARK: Private

    private var service: ReciterSizeInfoRetriever!
    private var fileSystem: FileSystemFake!

    private let baseURL = URL(validURL: "http://example.com")

    private let quran = Quran.hafsMadani1405
    private let gappedReciter: Reciter = .gappedReciter
    private let gaplessReciter: Reciter = .gaplessReciter

    private func runNoDownloadsTest(
        _ reciters: [Reciter],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let sizeInfo = await service.getDownloadedSizes(for: reciters, quran: quran)

        let expectedDownloads = reciters.map { reciter in
            (reciter, AudioDownloadedSize.zero(quran: quran))
        }
        XCTAssertEqual(sizeInfo, expectedDownloads.toDictionary(), file: file, line: line)
    }

    private func runFullDownloadedTest(
        _ reciters: [Reciter],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let expectedDownloads = reciters.map { reciter in (reciter, simulateAllFilesDownloaded(reciter)) }

        let sizeInfo = await service.getDownloadedSizes(for: reciters, quran: quran)
        XCTAssertEqual(sizeInfo, expectedDownloads.toDictionary(), file: file, line: line)
    }

    private func simulateAllFilesDownloaded(_ reciter: Reciter, fileSize: Int = 100) -> AudioDownloadedSize {
        let files = reciter.audioFiles(baseURL: baseURL, from: quran.firstVerse, to: quran.lastVerse)

        let directory = reciter.localFolder()
        let fileURLs = files.map(\.local)
        fileSystem.filesInDirectory[directory] = fileURLs
        fileURLs.forEach { fileSystem.setResourceValues($0, fileSize: fileSize) }

        return AudioDownloadedSize(
            downloadedSizeInBytes: UInt64(fileSize * files.count),
            downloadedSuraCount: quran.suras.count,
            surasCount: quran.suras.count
        )
    }

    private func runPartialDownloadedGappedTest(
        ayahs: [AyahNumber],
        fileSize: Int = 100,
        downloadedSuraCount: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let reciter = gappedReciter
        let files = ayahs.map { ayah in
            reciter.relativePath
                .stringByAppendingPath(ayah.sura.suraNumber.as3DigitString() + ayah.ayah.as3DigitString())
                .stringByAppendingExtension("mp3")
        }

        let directory = reciter.localFolder()
        let fileURLs = files.map { directory.appendingPathComponent($0) }
        fileSystem.filesInDirectory[directory] = fileURLs
        fileURLs.forEach { fileSystem.setResourceValues($0, fileSize: fileSize) }

        let expectedDownload = AudioDownloadedSize(
            downloadedSizeInBytes: UInt64(fileSize * files.count),
            downloadedSuraCount: downloadedSuraCount,
            surasCount: quran.suras.count
        )

        let sizeInfo = await service.getDownloadedSizes(for: [reciter], quran: quran)
        XCTAssertEqual(sizeInfo, [reciter: expectedDownload], file: file, line: line)
    }

    private func runPartialDownloadedGaplessTest(
        suras: [Sura],
        dbDownloaded: Bool,
        fileSize: Int = 100,
        downloadedSuraCount: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let reciter = gaplessReciter
        let dbFiles = dbDownloaded ? [reciter.relativePath.stringByAppendingPath(reciter.gaplessDatabaseDB)] : []
        let files = suras.map { sura in
            reciter.relativePath
                .stringByAppendingPath(sura.suraNumber.as3DigitString())
                .stringByAppendingExtension("mp3")
        } + dbFiles

        let directory = reciter.localFolder()
        let fileURLs = files.map { directory.appendingPathComponent($0) }
        fileSystem.filesInDirectory[directory] = fileURLs
        fileURLs.forEach { fileSystem.setResourceValues($0, fileSize: fileSize) }

        let expectedDownload = AudioDownloadedSize(
            downloadedSizeInBytes: UInt64(fileSize * files.count),
            downloadedSuraCount: downloadedSuraCount,
            surasCount: quran.suras.count
        )

        let sizeInfo = await service.getDownloadedSizes(for: [reciter], quran: quran)
        XCTAssertEqual(sizeInfo, [reciter: expectedDownload], file: file, line: line)
    }
}

private extension [(Reciter, AudioDownloadedSize)] {
    func toDictionary() -> [Reciter: AudioDownloadedSize] {
        Dictionary(uniqueKeysWithValues: map { ($0.0, $0.1) })
    }
}
