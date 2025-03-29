//
//  MoreMenuThemeSettingsViewModel.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import Combine
import NoorUI
import QuranText
import QuranTextKit
import VLogging

@MainActor
final class MoreMenuThemeSettingsViewModel: ObservableObject {
    private var cancellables: Set<AnyCancellable> = []

    private let themeService = ThemeService.shared
    @Published var themeStyle: ThemeStyle
    @Published var appearanceMode: AppearanceMode

    private let fontSizePreferences = FontSizePreferences.shared
    @Published var arabicFontSize: FontSize
    @Published var translationFontSize: FontSize

    init() {
        themeStyle = themeService.themeStyle
        appearanceMode = themeService.appearanceMode

        translationFontSize = fontSizePreferences.translationFontSize
        arabicFontSize = fontSizePreferences.arabicFontSize

        $themeStyle
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set themeStyle \(newValue)")
                self?.themeService.themeStyle = newValue
            }
            .store(in: &cancellables)

        $appearanceMode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set appearanceMode \(newValue)")
                self?.themeService.appearanceMode = newValue
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
    }
}
