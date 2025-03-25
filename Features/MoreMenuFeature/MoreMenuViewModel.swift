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

@MainActor
public protocol MoreMenuListener: AnyObject {
    func onTranslationsSelectionsTapped()
    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool)
}

@MainActor
final class MoreMenuViewModel: ObservableObject {
    // MARK: Lifecycle

    init(model: MoreMenuModel) {
        self.model = model
        state = model.state

        mode = preferences.quranMode
        wordPointerEnabled = model.isWordPointerActive
        wordPointerType = wordTextPreferences.wordTextType
        translationFontSize = fontSizePreferences.translationFontSize
        arabicFontSize = fontSizePreferences.arabicFontSize
        twoPagesEnabled = preferences.twoPagesEnabled
        verticalScrollingEnabled = preferences.verticalScrollingEnabled
        appearanceMode = themeService.appearanceMode

        state.twoPages = (model.state.twoPages == .conditional && TwoPagesUtils.hasEnoughHorizontalSpace()) ? .conditional : .alwaysOff

        $mode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set quran model \(newValue)")
                self?.preferences.quranMode = newValue
            }
            .store(in: &cancellables)

        $wordPointerEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set is word pointer active \(newValue)")
                self?.listener?.onIsWordPointerActiveUpdated(to: newValue)
            }
            .store(in: &cancellables)

        $wordPointerType
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set word pointer type \(newValue)")
                self?.wordTextPreferences.wordTextType = newValue
            }
            .store(in: &cancellables)

        $translationFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set translation font size \(newValue)")
                self?.fontSizePreferences.translationFontSize = newValue
            }
            .store(in: &cancellables)

        $arabicFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set arabic font size \(newValue)")
                self?.fontSizePreferences.arabicFontSize = newValue
            }
            .store(in: &cancellables)

        $twoPagesEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set two pages enabled \(newValue)")
                self?.preferences.twoPagesEnabled = newValue
            }
            .store(in: &cancellables)

        $verticalScrollingEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set vertical scrolling enabled \(newValue)")
                self?.preferences.verticalScrollingEnabled = newValue
            }
            .store(in: &cancellables)

        $appearanceMode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set appearanceMode \(newValue)")
                self?.themeService.appearanceMode = newValue
            }
            .store(in: &cancellables)
    }

    // MARK: Public

    @Published public var mode: QuranMode {
        didSet {
            if mode == .translation {
                wordPointerEnabled = false
            }
        }
    }

    // MARK: Internal

    weak var listener: MoreMenuListener?

    var state: MoreMenuControlsState

    @Published var wordPointerEnabled: Bool
    @Published var wordPointerType: WordTextType
    @Published var translationFontSize: FontSize
    @Published var arabicFontSize: FontSize

    @Published var twoPagesEnabled: Bool
    @Published var verticalScrollingEnabled: Bool

    @Published var appearanceMode: AppearanceMode

    func selectTranslations() {
        logger.info("More Menu: translations selections tapped")
        listener?.onTranslationsSelectionsTapped()
    }

    // MARK: Private

    private let model: MoreMenuModel
    private let themeService = ThemeService.shared
    private let wordTextPreferences = WordTextPreferences.shared
    private let preferences = QuranContentStatePreferences.shared
    private let fontSizePreferences = FontSizePreferences.shared

    private var cancellables: Set<AnyCancellable> = []
}
