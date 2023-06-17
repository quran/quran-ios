//
//  GappedAudioRequestBuilderTests.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
import QuranAudio
import QuranKit
import XCTest
@testable import QuranAudioKit

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

    func testAudioRequestContainsBismillahWhenThePlaybackIsNotRepeated() async throws {
        let from = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))
        let to = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))

        let request = try await audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .one
        )
        let audioRequest = try XCTUnwrap(request as? GappedAudioRequest).request
        let bismillahFile = audioRequest.files.first { audioFile in
            audioFile.url.lastPathComponent == "001001.mp3"
        }
        XCTAssertNotNil(bismillahFile)
    }

    func testAudioRequestDoesNotContainsBismillahWhenThePlaybackIsRepeated() async throws {
        let from = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))
        let to = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))

        let request = try await audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .indefinite
        )
        let audioRequest = try XCTUnwrap(request as? GappedAudioRequest).request
        let bismillahFile = audioRequest.files.first { audioFile in
            audioFile.url.lastPathComponent == "001001.mp3"
        }
        XCTAssertNil(bismillahFile)
    }

    func testAudioRequestContainsBismillahIfTheRepeatIsInContinuationFromPreviousSura() async throws {
        let from = try XCTUnwrap(AyahNumber(sura: quran.firstSura, ayah: quran.firstSura.lastVerse.ayah))
        let to = try XCTUnwrap(AyahNumber(sura: quran.suras[1], ayah: quran.suras[1].firstVerse.ayah))

        let request = try await audioRequestBuilder.buildRequest(
            with: reciter,
            from: from,
            to: to,
            frameRuns: .one,
            requestRuns: .indefinite
        )
        let audioRequest = try XCTUnwrap(request as? GappedAudioRequest).request
        let bismillahFile = audioRequest.files.first { audioFile in
            audioFile.url.lastPathComponent == "001001.mp3"
        }
        XCTAssertNotNil(bismillahFile)
    }
}
