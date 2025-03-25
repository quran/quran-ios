//
//  MoreMenuModel.swift
//
//
//  Created by Afifi, Mohamed on 8/29/21.
//

public struct MoreMenuModel {
    // MARK: Lifecycle

    public init(isWordPointerActive: Bool, state: MoreMenuControlsState) {
        self.isWordPointerActive = isWordPointerActive
        self.state = state
    }

    // MARK: Public

    public var isWordPointerActive: Bool
    public var state: MoreMenuControlsState
}

public enum ConfigState {
    case alwaysOn
    case alwaysOff
    case conditional
}

public struct MoreMenuControlsState {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var mode = ConfigState.conditional
    public var translationsSelection = ConfigState.conditional
    public var wordPointer = ConfigState.conditional
    public var orientation = ConfigState.conditional
    public var fontSize = ConfigState.conditional
    public var twoPages = ConfigState.conditional
    public var verticalScrolling = ConfigState.conditional
    public var theme = ConfigState.conditional
}
