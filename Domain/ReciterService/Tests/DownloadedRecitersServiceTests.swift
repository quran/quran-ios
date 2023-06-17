//
//  DownloadedRecitersServiceTests.swift
//
//
//  Created by Zubair Khan on 1/2/23.
//

import Foundation
import QuranAudio
import XCTest
@testable import ReciterService

class DownloadedRecitersServiceTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        service = DownloadedRecitersService()
    }

    func testFilterDownloadedReciters() {
        let reciter1 = createReciter(id: 1)
        let reciter2 = createReciter(id: 2)
        let reciter3 = createReciter(id: 3)
        let reciter4 = createReciter(id: 4)
        let reciter5 = createReciter(id: 5)
        let allReciters = Array(arrayLiteral: reciter1, reciter2, reciter3, reciter4, reciter5)

        // Cleanup existing directories
        deleteReciterDirs(allReciters)

        // Should return empty list when no downloads exist
        var downloadedReciters = service.downloadedReciters(allReciters)
        XCTAssertEqual(downloadedReciters, [])

        createReciterDir(reciter2)
        createReciterDir(reciter4)
        createReciterDir(reciter5)

        // Reciter2's directory will be empty, therefore it shouldn't be considered a downloaded reciter
        createReciterFile(reciter4)
        createReciterFile(reciter5)

        downloadedReciters = service.downloadedReciters(allReciters)
        XCTAssertEqual(downloadedReciters, [reciter4, reciter5])
    }

    // MARK: Private

    private var service: DownloadedRecitersService!
    private var fileManager = FileManager.default

    private func deleteReciterDirs(_ reciters: [Reciter]) {
        reciters.forEach { reciter in
            try? fileManager.removeItem(at: reciter.localFolder())
        }
    }

    private func createReciterDir(_ reciter: Reciter) {
        try? fileManager.createDirectory(at: reciter.localFolder(), withIntermediateDirectories: true)
    }

    private func createReciterFile(_ reciter: Reciter) {
        let fileURL = reciter.localFolder().appendingPathComponent("surah1")
        try? "testing123".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func createReciter(id: Int) -> Reciter {
        let name = "reciter" + String(id)
        return Reciter(
            id: id,
            nameKey: name,
            directory: String(id),
            audioURL: URL(validURL: "http://example.com"),
            audioType: .gapless(databaseName: name),
            hasGaplessAlternative: false,
            category: .arabic
        )
    }
}
