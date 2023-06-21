//
//  SettingsTabInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-03-03.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Analytics
import AudioDownloadsFeature
import Combine
import Foundation
import Localization
import QuranAudio
import QuranAudioKit
import QuranViewFeature
import SettingsFeature
import SettingsService
import TranslationsFeature
import UIKit
import UIx
import VLogging

@MainActor
protocol SettingsTabPresentable: TabPresenter {
    func presentShareApp(_ view: UIView)
    func presentContactUs()
}

final class SettingsTabInteractor: TabInteractor {
    struct Deps {
        let analytics: AnalyticsLibrary
        let themeService: ThemeSettingsService
        let reviewService: ReviewService
        let audioPreferences = AudioPreferences.shared
        let audioDownloadsBuilder: AudioDownloadsBuilder
        let translationsListBuilder: TranslationsListBuilder
        let settingsBuilder: SettingsBuilder
    }

    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, deps: Deps) {
        self.deps = deps
        super.init(quranBuilder: quranBuilder)
    }

    // MARK: Internal

    let deps: Deps

    var settingsPresenter: SettingsTabPresentable? {
        presenter as? SettingsTabPresentable
    }

    override func start() {
        deps.themeService.startObserving()

        // show root settings
        showRootSettings(rootSettings, title: lAndroid("menu_settings"))
    }

    // MARK: - Navigation

    func showRootSettings(_ settings: [SettingSection], title: String) {
        let settingsViewController = deps.settingsBuilder.build(title: title, settings: settings)
        presenter?.setViewControllers([settingsViewController], animated: false)
    }

    func push(_ settings: [SettingSection], title: String) {
        let settingsViewController = deps.settingsBuilder.build(title: title, settings: settings)
        presenter?.pushViewController(settingsViewController, animated: true)
    }

    func showSingleChoiceSelector<T: Hashable>(
        title: String,
        sections: [SingleChoiceSection<T>],
        selected: T?,
        itemText: @escaping (T) -> String,
        onSelection: @escaping (T) -> Void
    ) {
        let viewController = singleChoiceSelector(
            sections: sections,
            selected: selected,
            itemText: itemText,
            onSelection: { [weak self] item in
                onSelection(item)
                self?.presenter?.popViewController(animated: true)
            }
        )
        viewController.title = title
        presenter?.pushViewController(viewController, animated: true)
    }

    // MARK: Private

    // MARK: - Settings

    private var themeSection: SettingSection {
        let theme = ThemeSetting(theme: deps.themeService.theme)
        return SettingSection(section: "theme", settings: [
            theme,
        ])
    }

    private var audioSection: SettingSection {
        let audioEndPublisher = deps.audioPreferences.$audioEnd
            .prepend(deps.audioPreferences.audioEnd)
            .map(\.name)
            .eraseToAnyPublisher()
        let audioEndSetting = SubtitleSetting(
            name: l("audio.download-play-amount"),
            image: .symbol("headphones"),
            subtitle: audioEndPublisher
        ) { [weak self] _ in
            self?.showAudioEndChoices()
        }
        let audioManager = Setting(name: lAndroid("audio_manager"), image: .symbol("square.and.arrow.down")) { [weak self] _ in
            self?.presentAudioDownloads()
        }
        return SettingSection(section: "audio", settings: [
            audioEndSetting,
            audioManager,
        ])
    }

    private var translationSection: SettingSection {
        let translations = Setting(name: lAndroid("prefs_translations"), image: .symbol("globe")) { [weak self] _ in
            self?.presentTranslationsList()
        }
        return SettingSection(section: "translation", settings: [
            translations,
        ])
    }

    private var feedbackSection: SettingSection {
        let shareApp = Setting(name: l("share_app"), image: .symbol("square.and.arrow.up")) { [weak self] view in
            self?.deps.analytics.shareApp()
            self?.settingsPresenter?.presentShareApp(view)
        }
        let writeReview = Setting(name: l("write_review"), image: .symbol("star")) { [weak self] _ in
            logger.info("Settings: Navigate to app store to write a review.")
            self?.deps.reviewService.openAppReview()
        }
        let contactUs = Setting(name: l("contact_us"), image: .symbol("envelope")) { [weak self] _ in
            logger.info("Settings: presentContactUs")
            self?.settingsPresenter?.presentContactUs()
        }

        return SettingSection(section: "feedback", settings: [
            shareApp,
            writeReview,
            contactUs,
        ])
    }

    private var aboutSection: SettingSection {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let appVersionSetting = InfoSetting(name: l("app_version"), details: appVersion)
        return SettingSection(section: "about", settings: [appVersionSetting])
    }

    private var rootSettings: [SettingSection] {
        [
            themeSection,
            audioSection,
            translationSection,
            feedbackSection,
            aboutSection,
        ]
    }

    // MARK: - Actions

    private func presentTranslationsList() {
        logger.info("Settings: presentTranslationsList")
        Task { @MainActor in
            let viewController = await deps.translationsListBuilder.build(showEditButton: true)
            presenter?.pushViewController(viewController, animated: true)
        }
    }

    private func presentAudioDownloads() {
        logger.info("Settings: presentAudioDownloads")
        Task { @MainActor in
            let viewController = await deps.audioDownloadsBuilder.build()
            presenter?.pushViewController(viewController, animated: true)
        }
    }

    private func showAudioEndChoices() {
        showSingleChoiceSelector(
            title: l("audio.download-play-amount"),
            sections: [SingleChoiceSection(
                header: l("audio.download-play-amount.description"),
                items: [AudioEnd.juz, .sura, .page]
            )],
            selected: deps.audioPreferences.audioEnd,
            itemText: { $0.name },
            onSelection: { [weak self] item in
                self?.deps.audioPreferences.audioEnd = item
            }
        )
    }
}

private extension AnalyticsLibrary {
    func shareApp() {
        logEvent("ShareApp", value: "Shared!")
    }
}
