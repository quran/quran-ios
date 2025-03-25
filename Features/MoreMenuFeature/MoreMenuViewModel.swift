//
//  MoreMenuViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import NoorUI
import QuranText
import QuranTextKit
import VLogging
import WordTextService

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

@MainActor
public protocol MoreMenuListener: AnyObject {
    func onTranslationsSelectionsTapped()
    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool)
}

@MainActor
final class MoreMenuViewModel {
    // MARK: Lifecycle

    init(model: MoreMenuModel) {
        self.model = model

        let translationType = wordTextPreferences.wordTextType
        store = MoreMenuStore(
            mode: MoreMenu.Mode(preferences.quranMode),
            wordPointerEnabled: model.isWordPointerActive,
            wordPointerType: MoreMenu.TranslationPointerType(translationType),
            translationFontSize: fontSizePreferences.translationFontSize,
            arabicFontSize: fontSizePreferences.arabicFontSize,
            twoPagesEnabled: preferences.twoPagesEnabled,
            verticalScrollingEnabled: preferences.verticalScrollingEnabled,
            appearanceMode: themeService.appearanceMode
        )

        store.state = model.state
        store.state.twoPages = (model.state.twoPages == .custom && TwoPagesUtils.hasEnoughHorizontalSpace()) ? .custom : .alwaysOff

        store.selectTranslation = { [weak self] in
            logger.info("More Menu: translations selections tapped")
            self?.listener?.onTranslationsSelectionsTapped()
        }

        store.$mode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set quran model \(newValue)")
                self?.preferences.quranMode = newValue.mode
            }
            .store(in: &cancellables)

        store.$wordPointerEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set is word pointer active \(newValue)")
                self?.listener?.onIsWordPointerActiveUpdated(to: newValue)
            }
            .store(in: &cancellables)

        store.$wordPointerType
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set word pointer type \(newValue)")
                self?.updateTranslationTypeTo(newValue)
            }
            .store(in: &cancellables)

        store.$translationFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set translation font size \(newValue)")
                self?.fontSizePreferences.translationFontSize = newValue
            }
            .store(in: &cancellables)

        store.$arabicFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set arabic font size \(newValue)")
                self?.fontSizePreferences.arabicFontSize = newValue
            }
            .store(in: &cancellables)

        store.$twoPagesEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set two pages enabled \(newValue)")
                self?.preferences.twoPagesEnabled = newValue
            }
            .store(in: &cancellables)

        store.$verticalScrollingEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set vertical scrolling enabled \(newValue)")
                self?.preferences.verticalScrollingEnabled = newValue
            }
            .store(in: &cancellables)

        store.$appearanceMode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set appearanceMode \(newValue)")
                self?.themeService.appearanceMode = newValue
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    weak var listener: MoreMenuListener?

    let store: MoreMenuStore

    func updateTranslationTypeTo(_ newType: MoreMenu.TranslationPointerType) {
        wordTextPreferences.wordTextType = WordTextType(newType)
    }

    // MARK: Private

    private let model: MoreMenuModel
    private let themeService = ThemeService.shared
    private let wordTextPreferences = WordTextPreferences.shared
    private let preferences = QuranContentStatePreferences.shared
    private let fontSizePreferences = FontSizePreferences.shared

    private var cancellables: Set<AnyCancellable> = []
}

private extension MoreMenu.Mode {
    init(_ mode: QuranMode) {
        switch mode {
        case .arabic: self = .arabic
        case .translation: self = .translation
        }
    }

    var mode: QuranMode {
        switch self {
        case .arabic: return .arabic
        case .translation: return .translation
        }
    }
}

private extension MoreMenu.TranslationPointerType {
    init(_ value: WordTextType) {
        switch value {
        case .transliteration:
            self = .transliteration
        case .translation:
            self = .translation
        }
    }
}

private extension WordTextType {
    init(_ value: MoreMenu.TranslationPointerType) {
        switch value {
        case .transliteration:
            self = .transliteration
        case .translation:
            self = .translation
        }
    }
}
