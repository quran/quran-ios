//
//  RunsPreferenceTests.swift
//
//
//  Created by Abdullah Levin on 2026-09-08.
//

import Foundation
import QuranAudio
import XCTest
@testable import QuranAudioKit

final class RunsPreferenceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        for key in keys {
            originalValues[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        for key in keys {
            if let value = originalValues[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    func testMissingPreferencesDefaultToOneRun() {
        XCTAssertEqual(preferences.verseRuns, .finite(1))
        XCTAssertEqual(preferences.listRuns, .finite(1))
    }

    func testFiniteRunsSurviveARoundTrip() {
        for count in [1, 3, 25, 100] {
            preferences.verseRuns = .finite(count)
            preferences.listRuns = .finite(count)
            XCTAssertEqual(preferences.verseRuns, .finite(count))
            XCTAssertEqual(preferences.listRuns, .finite(count))
            for key in keys {
                XCTAssertEqual(UserDefaults.standard.integer(forKey: key), count)
            }
        }
    }

    func testEndlessRepetitionIsStoredAsZero() {
        preferences.verseRuns = .indefinite
        preferences.listRuns = .indefinite
        for key in keys {
            XCTAssertEqual(UserDefaults.standard.object(forKey: key) as? Int, 0)
        }
        XCTAssertEqual(preferences.verseRuns, .indefinite)
        XCTAssertEqual(preferences.listRuns, .indefinite)
    }

    func testNegativeStoredCountsDefaultToOneRun() {
        for key in keys {
            UserDefaults.standard.set(-1, forKey: key)
        }
        XCTAssertEqual(preferences.verseRuns, .finite(1))
        XCTAssertEqual(preferences.listRuns, .finite(1))
    }

    func testInvalidWritesPreserveSavedCounts() {
        preferences.verseRuns = .finite(3)
        preferences.listRuns = .indefinite
        for count in [0, -3] {
            preferences.verseRuns = .finite(count)
            preferences.listRuns = .finite(count)
            XCTAssertEqual(preferences.verseRuns, .finite(3))
            XCTAssertEqual(preferences.listRuns, .indefinite)
            XCTAssertEqual(UserDefaults.standard.integer(forKey: keys[0]), 3)
            XCTAssertEqual(UserDefaults.standard.integer(forKey: keys[1]), 0)
        }
    }

    func testInvalidWritesLeaveMissingPreferencesUnset() {
        preferences.verseRuns = .finite(0)
        preferences.listRuns = .finite(-1)
        for key in keys {
            XCTAssertNil(UserDefaults.standard.object(forKey: key))
        }
        XCTAssertEqual(preferences.verseRuns, .finite(1))
        XCTAssertEqual(preferences.listRuns, .finite(1))
    }

    private let preferences = AudioPreferences.shared
    private let keys = ["audioVerseRuns", "audioListRuns"]
    private var originalValues: [String: Any] = [:]
}
