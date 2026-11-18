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

    public struct ParameterizedEvent: Equatable, Sendable {
        // MARK: Lifecycle

        public init(name: String, parameters: [String: AnalyticsValue]) {
            self.name = name
            self.parameters = parameters
        }

        // MARK: Public

        public let name: String
        public let parameters: [String: AnalyticsValue]
    }

    public struct UserPropertyChange: Equatable, Sendable {
        // MARK: Lifecycle

        public init(name: String, value: String?) {
            self.name = name
            self.value = value
        }

        // MARK: Public

        public let name: String
        public let value: String?
    }

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var events: [Event] {
        state.withCriticalRegion { $0.events }
    }

    public var parameterizedEvents: [ParameterizedEvent] {
        state.withCriticalRegion { $0.parameterizedEvents }
    }

    /// Every user property set, in order, including clears.
    public var userPropertyChanges: [UserPropertyChange] {
        state.withCriticalRegion { $0.userPropertyChanges }
    }

    /// The latest user ID set, nil once cleared.
    public var userID: String? {
        state.withCriticalRegion { $0.userIDChanges.last ?? nil }
    }

    /// Every user ID set, in order, including clears.
    public var userIDChanges: [String?] {
        state.withCriticalRegion { $0.userIDChanges }
    }

    /// The first `count` user IDs set, waiting until that many are.
    public func userIDChanges(count: Int) async -> [String?] {
        await withCheckedContinuation { continuation in
            let changes: [String?]? = state.withCriticalRegion { state in
                if state.userIDChanges.count >= count {
                    return Array(state.userIDChanges.prefix(count))
                }
                state.userIDWaiters.append((count, continuation))
                return nil
            }
            if let changes {
                continuation.resume(returning: changes)
            }
        }
    }

    /// The parameterized events named `name`, in order.
    public func parameterizedEvents(named name: String) -> [[String: AnalyticsValue]] {
        parameterizedEvents.filter { $0.name == name }.map(\.parameters)
    }

    public func logEvent(_ name: String, value: String) {
        state.withCriticalRegion { $0.events.append(Event(name: name, value: value)) }
    }

    public func logEvent(_ name: String, parameters: [String: AnalyticsValue]) {
        state.withCriticalRegion {
            $0.parameterizedEvents.append(ParameterizedEvent(name: name, parameters: parameters))
        }
    }

    public func setUserProperty(_ value: String?, forName name: String) {
        state.withCriticalRegion { $0.userPropertyChanges.append(UserPropertyChange(name: name, value: value)) }
    }

    public func setUserID(_ userID: String?) {
        let satisfied = state.withCriticalRegion { state in
            state.userIDChanges.append(userID)
            let changes = state.userIDChanges
            let satisfied = state.userIDWaiters
                .filter { $0.count <= changes.count }
                .map { ($0.continuation, Array(changes.prefix($0.count))) }
            state.userIDWaiters.removeAll { $0.count <= changes.count }
            return satisfied
        }
        for (continuation, changes) in satisfied {
            continuation.resume(returning: changes)
        }
    }

    // MARK: Private

    private struct State: Sendable {
        var events: [Event] = []
        var parameterizedEvents: [ParameterizedEvent] = []
        var userPropertyChanges: [UserPropertyChange] = []
        var userIDChanges: [String?] = []
        var userIDWaiters: [(count: Int, continuation: CheckedContinuation<[String?], Never>)] = []
    }

    private let state = ManagedCriticalState(State())
}
