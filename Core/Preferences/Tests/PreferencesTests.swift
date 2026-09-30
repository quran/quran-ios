//
//  PreferencesTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Combine
import XCTest
@testable import Preferences

final class PreferencesTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        suiteName = "PreferencesTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        preferences = Preferences(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        preferences = nil
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testAssigningNilToOptionalPreferenceRemovesStoredValue() {
        let holder = OptionalPreferenceHolder(preferences: preferences)
        holder.value = "2.6.0"

        holder.value = nil

        XCTAssertNil(userDefaults.object(forKey: Self.optionalKey.key))
        XCTAssertEqual(holder.value, Self.optionalKey.defaultValue)
    }

    func testNonNilOptionalPreferenceRoundTrips() {
        let holder = OptionalPreferenceHolder(preferences: preferences)

        holder.value = "2.6.0"

        XCTAssertEqual(holder.value, "2.6.0")
        XCTAssertEqual(userDefaults.string(forKey: Self.optionalKey.key), "2.6.0")
    }

    func testUnsetOptionalPreferenceReturnsDefaultValue() {
        let holder = OptionalPreferenceHolder(preferences: preferences)

        XCTAssertEqual(holder.value, Self.optionalKey.defaultValue)
    }

    func testAssigningNilToOptionalPreferenceNotifiesObservers() {
        let holder = OptionalPreferenceHolder(preferences: preferences)
        holder.value = "2.6.0"
        var notifiedKeys: [String] = []
        let cancellable = preferences.notifications.sink { notifiedKeys.append($0) }

        holder.value = nil

        XCTAssertEqual(notifiedKeys, [Self.optionalKey.key])
        cancellable.cancel()
    }

    // MARK: Private

    private final class OptionalPreferenceHolder {
        // MARK: Lifecycle

        init(preferences: Preferences) {
            _value = Preference(PreferencesTests.optionalKey, preferences: preferences)
        }

        // MARK: Internal

        @Preference var value: String?
    }

    private static let optionalKey = PreferenceKey<String?>(key: "optionalString", defaultValue: "default")

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var preferences: Preferences!
}
