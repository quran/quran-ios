//
//  AnalyticsLibrarySpy.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Analytics
import Utilities

public final class AnalyticsLibrarySpy: AnalyticsLibrary, Sendable {
    public struct Event: Equatable, Sendable {
        // MARK: Lifecycle

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }

        // MARK: Public

        public let name: String
        public let value: String
    }

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var events: [Event] {
        state.withCriticalRegion { $0.events }
    }

    public var userProperties: [String: String] {
        state.withCriticalRegion { $0.userProperties }
    }

    public func userProperty(_ property: AnalyticsUserProperty) -> String? {
        userProperties[property.rawValue]
    }

    /// Every value set for `property`, in order, including clears.
    public func changes(of property: AnalyticsUserProperty) -> [String?] {
        state.withCriticalRegion { $0.userPropertyChanges }
            .filter { $0.name == property.rawValue }
            .map(\.value)
    }

    public func logEvent(_ name: String, value: String) {
        state.withCriticalRegion { $0.events.append(Event(name: name, value: value)) }
    }

    public func logEvent(_: String, parameters _: [String: AnalyticsValue]) {}

    public func setUserProperty(_ value: String?, forName name: String) {
        state.withCriticalRegion {
            $0.userProperties[name] = value
            $0.userPropertyChanges.append((name, value))
        }
    }

    // MARK: Private

    private struct State: Sendable {
        var events: [Event] = []
        var userProperties: [String: String] = [:]
        var userPropertyChanges: [(name: String, value: String?)] = []
    }

    private let state = ManagedCriticalState(State())
}
