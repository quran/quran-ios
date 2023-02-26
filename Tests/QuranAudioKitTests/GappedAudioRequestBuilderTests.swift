//
//  GappedAudioRequestBuilderTests.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
@testable import QuranAudioKit
import QuranKit
import XCTest

class GappedAudioRequestBuilderTests: XCTestCase {
    private var audioRequestBuilder: QuranAudioRequestBuilder!
    private var reciter: Reciter!
    private let quran = Quran.hafsMadani1405

    override func setUpWithError() throws {
        reciter = .gappedReciter
        audioRequestBuilder = GappedAudioRequestBuilder()
    }

    override func tearDown() async throws {
        audioRequestBuilder = nil
        reciter = nil
    }

    func testAudioRequestContainsBismillahWhenThePlaybackIsNotRepeated() throws {
        let expectation = expectation(description: "waiting for promise to fulfill")
        let from = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))
        let to = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))

        _ = audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .one
        ).done { audioRequest in
            let audioRequest = try XCTUnwrap(audioRequest as? GappedAudioRequest).request
            let bismillahFile = audioRequest.files.first { audioFile in
                audioFile.url.lastPathComponent == "001001.mp3"
            }
            XCTAssertNotNil(bismillahFile)
            expectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAudioRequestDoesNotContainsBismillahWhenThePlaybackIsRepeated() throws {
        let expectation = expectation(description: "waiting for promise to fulfill")
        let from = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))
        let to = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))

        _ = audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .indefinite
        ).done { audioRequest in
            let audioRequest = try XCTUnwrap(audioRequest as? GappedAudioRequest).request
            let bismillahFile = audioRequest.files.first { audioFile in
                audioFile.url.lastPathComponent == "001001.mp3"
            }
            XCTAssertNil(bismillahFile)
            expectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAudioRequestContainsBismillahIfTheRepeatIsInContinuationFromPreviousSura() throws {
        let expectation = expectation(description: "waiting for promise to fulfill")
        let from = try XCTUnwrap(AyahNumber(sura: quran.firstSura, ayah: quran.firstSura.lastVerse.ayah))
        let to = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))

        _ = audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .indefinite
        ).done { audioRequest in
            let audioRequest = try XCTUnwrap(audioRequest as? GappedAudioRequest).request
            let bismillahFile = audioRequest.files.first { audioFile in
                audioFile.url.lastPathComponent == "001001.mp3"
            }
            XCTAssertNotNil(bismillahFile)
            expectation.fulfill()
        }
        .catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
