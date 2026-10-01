//
//  AudioEndPreferenceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import Foundation
import QuranAudio
import XCTest
@testable import QuranAudioKit

final class AudioEndPreferenceTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        originalValue = UserDefaults.standard.object(forKey: key)
    }

    override func tearDown() {
        if let originalValue {
            UserDefaults.standard.set(originalValue, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        super.tearDown()
    }

    func test_rawValues_stayStable() {
        // Saved by raw value: changing one would change what users saved.
        let expected: [AudioEnd: Int] = [.sura: 0, .juz: 1, .page: 2, .quran: 3, .quarter: 4, .hizb: 5]

        for (audioEnd, rawValue) in expected {
            XCTAssertEqual(audioEnd.rawValue, rawValue, "\(audioEnd)")
            XCTAssertEqual(AudioEnd(rawValue: rawValue), audioEnd)
        }
    }

    func test_savedRawValues_readBackAsTheirAudioEnd() {
        for rawValue in 0 ... 5 {
            UserDefaults.standard.set(rawValue, forKey: key)

            XCTAssertEqual(AudioPreferences.shared.audioEnd, AudioEnd(rawValue: rawValue))
        }
    }

    func test_writingQuarterAndHizb_savesTheirRawValues() {
        AudioPreferences.shared.audioEnd = .quarter
        XCTAssertEqual(UserDefaults.standard.integer(forKey: key), 4)

        AudioPreferences.shared.audioEnd = .hizb
        XCTAssertEqual(UserDefaults.standard.integer(forKey: key), 5)
    }

    func test_playUpToChoices_goFromSmallestToLargest() {
        XCTAssertEqual(AudioEnd.playUpToChoices, [.page, .quarter, .hizb, .juz, .sura, .quran])
    }

    // MARK: Private

    private let key = "audioEndKey"
    private var originalValue: Any?
}
