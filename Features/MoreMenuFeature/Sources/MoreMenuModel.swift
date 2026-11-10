//
//  MoreMenuModel.swift
//
//
//  Created by Afifi, Mohamed on 8/29/21.
//

public struct MoreMenuModel {
    // MARK: Lifecycle

    public init(isWordPointerActive: Bool, state: MoreMenuControlsState, twoPagesEnabledByDefault: Bool = false) {
        self.isWordPointerActive = isWordPointerActive
        self.state = state
        self.twoPagesEnabledByDefault = twoPagesEnabledByDefault
    }

    // MARK: Public

    public var isWordPointerActive: Bool
    public var state: MoreMenuControlsState
    /// The two pages toggle's value for people who never chose, which depends on the reader's window.
    public var twoPagesEnabledByDefault: Bool
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
    public var arabicText = ConfigState.conditional
    public var wordPointer = ConfigState.conditional
    public var linePageDisplay = ConfigState.alwaysOff
    #if QURAN_SYNC
    public var ayahIndicators = ConfigState.alwaysOff
    #endif
    public var orientation = ConfigState.conditional
    public var fontSize = ConfigState.conditional
    public var twoPages = ConfigState.conditional
    public var verticalScrolling = ConfigState.conditional
    public var theme = ConfigState.conditional
}
