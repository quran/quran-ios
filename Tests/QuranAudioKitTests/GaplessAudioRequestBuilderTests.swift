//
//  GaplessAudioRequestBuilderTests.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-12.
//

import Foundation
@testable import QuranAudioKit
import QuranKit
import XCTest

class GaplessAudioRequestBuilderTests: XCTestCase {
    private var audioRequestBuilder: QuranAudioRequestBuilder!
    private var reciter: Reciter!

    override func setUpWithError() throws {
        reciter = .gaplessReciter
        try reciter.prepareGaplessReciterForTests(unZip: true)

        let timingRetriever = SQLiteReciterTimingRetriever(persistenceFactory: DefaultAyahTimingPersistenceFactory())
        audioRequestBuilder = GaplessAudioRequestBuilder(timingRetriever: timingRetriever)
    }

    override func tearDown() async throws {
        audioRequestBuilder = nil
        reciter = nil
    }

    func testAudioFrameStartingFromZeroSecondsWhenThePlaybackIsNotRepeated() throws {
        let expectation = expectation(description: "waiting for promise to fulfill")
        let from = try XCTUnwrap(AyahNumber(sura: Quran.madani.suras[1], ayah: 1))
        let to = try XCTUnwrap(AyahNumber(sura: Quran.madani.suras[1], ayah: 2))

        _ = audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .one
        ).done { audioRequest in
            let firstFrame = try XCTUnwrap(audioRequest.getRequest().files.first?.frames.first)
            XCTAssertEqual(firstFrame.startTime, .zero)
            expectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAudioFrameIsNotStartingFromZeroSecondsWhenThePlaybackIsRepeated() throws {
        let expectation = expectation(description: "waiting for promise to fulfill")
        let from = try XCTUnwrap(AyahNumber(sura: Quran.madani.suras[1], ayah: 1))
        let to = try XCTUnwrap(AyahNumber(sura: Quran.madani.suras[1], ayah: 2))

        _ = audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .indefinite
        ).done { audioRequest in
            let firstFrame = try XCTUnwrap(audioRequest.getRequest().files.first?.frames.first)
            XCTAssertNotEqual(firstFrame.startTime, .zero)
            expectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
