//
//  StoreOpenStartupState.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

/// Tracks launch while it opens the stores, so a full device is reported once
/// and launch continues exactly once after the stores open.
struct StoreOpenStartupState {
    enum Action: Equatable {
        /// The stores opened. Continue launching.
        case continueLaunch
        /// The device ran out of storage for the first time this launch. Report it and show the storage-full screen.
        case showStorageFull
        /// The device is still out of storage. Keep showing the storage-full screen.
        case keepWaiting
        case none
    }

    // MARK: Internal

    /// Whether launch is showing the storage-full screen and should open the stores again on retry.
    var isWaitingForStorage: Bool {
        phase == .waitingForStorage
    }

    mutating func storesOpened() -> Action {
        guard phase != .opened else { return .none }
        phase = .opened
        return .continueLaunch
    }

    mutating func storageFull() -> Action {
        switch phase {
        case .opening:
            phase = .waitingForStorage
            return .showStorageFull
        case .waitingForStorage:
            return .keepWaiting
        case .opened:
            return .none
        }
    }

    // MARK: Private

    private enum Phase {
        case opening
        case waitingForStorage
        case opened
    }

    private var phase = Phase.opening
}
