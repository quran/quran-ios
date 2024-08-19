//
//  MoreMenuStore.swift
//
//
//  Created by Afifi, Mohamed on 8/29/21.
//

import Combine
import QuranText

public enum MoreMenu {
    public enum Mode {
        case arabic
        case translation
    }

    public enum Rotation {
        case landscape
        case portrait
    }

    public enum TranslationPointerType {
        case translation
        case transliteration
    }
}

public enum ConfigState {
    case alwaysOn
    case alwaysOff
    case custom
}

public struct MoreMenuControlsState {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var mode = ConfigState.custom
    public var translationsSelection = ConfigState.custom
    public var wordPointer = ConfigState.custom
    public var orientation = ConfigState.custom
    public var fontSize = ConfigState.custom
    public var twoPages = ConfigState.custom
    public var verticalScrolling = ConfigState.custom
    public var theme = ConfigState.custom
}

public class MoreMenuStore: ObservableObject {
    // MARK: Lifecycle

    public init(
        mode: MoreMenu.Mode,
        wordPointerEnabled: Bool,
        wordPointerType: MoreMenu.TranslationPointerType,
        translationFontSize: FontSize,
        arabicFontSize: FontSize,
        twoPagesEnabled: Bool,
        verticalScrollingEnabled: Bool,
        theme: Theme
    ) {
        self.mode = mode
        self.wordPointerEnabled = wordPointerEnabled
        self.wordPointerType = wordPointerType
        self.translationFontSize = translationFontSize
        self.arabicFontSize = arabicFontSize
        self.twoPagesEnabled = twoPagesEnabled
        self.verticalScrollingEnabled = verticalScrollingEnabled
        self.theme = theme
    }

    // MARK: Public

    public var selectTranslation: (() -> Void)?

    @Published public var wordPointerEnabled: Bool
    @Published public var wordPointerType: MoreMenu.TranslationPointerType

    @Published public var translationFontSize: FontSize
    @Published public var arabicFontSize: FontSize

    @Published public var twoPagesEnabled: Bool
    @Published public var verticalScrollingEnabled: Bool

    @Published public var theme: Theme

    public var state = MoreMenuControlsState()

    @Published public var mode: MoreMenu.Mode {
        didSet {
            if mode == .translation {
                wordPointerEnabled = false
            }
        }
    }
}
