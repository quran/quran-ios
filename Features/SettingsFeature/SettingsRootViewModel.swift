//
//  SettingsRootViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-06-26.
//

import Analytics
import AudioDownloadsFeature
import Combine
import Localization
import NoorUI
import QuranAudio
import QuranAudioKit
import QuranProfileService
import ReadingSelectorFeature
import SettingsService
import TranslationsFeature
import UIKit
import UIx
import VLogging

@MainActor
final class SettingsRootViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        reviewService: ReviewService,
        quranProfileService: QuranProfileService,
        audioDownloadsBuilder: AudioDownloadsBuilder,
        translationsListBuilder: TranslationsListBuilder,
        readingSelectorBuilder: ReadingSelectorBuilder,
        diagnosticsBuilder: DiagnosticsBuilder,
        navigationController: UINavigationController
    ) {
        appearanceMode = themeService.appearanceMode
        audioEnd = audioPreferences.audioEnd
        self.analytics = analytics
        self.reviewService = reviewService
        self.quranProfileService = quranProfileService
        self.audioDownloadsBuilder = audioDownloadsBuilder
        self.translationsListBuilder = translationsListBuilder
        self.readingSelectorBuilder = readingSelectorBuilder
        self.diagnosticsBuilder = diagnosticsBuilder
        self.navigationController = navigationController

        themeService.appearanceModePublisher.assign(to: &$appearanceMode)
        audioPreferences.$audioEnd.assign(to: &$audioEnd)
    }

    // MARK: Internal

    let analytics: AnalyticsLibrary
    let reviewService: ReviewService
    let quranProfileService: QuranProfileService
    let audioDownloadsBuilder: AudioDownloadsBuilder
    let translationsListBuilder: TranslationsListBuilder
    let readingSelectorBuilder: ReadingSelectorBuilder
    let diagnosticsBuilder: DiagnosticsBuilder

    let contactUsService = ContactUsService()
    let themeService = ThemeService.shared
    let audioPreferences = AudioPreferences.shared

    weak var navigationController: UINavigationController?

    @Published var audioEnd: AudioEnd

    @Published var appearanceMode: AppearanceMode {
        didSet {
            themeService.appearanceMode = appearanceMode
        }
    }

    func navigateToAudioEndSelector() {
        logger.info("Settings: presentAudioEndSelector")
        showSingleChoiceSelector(
            title: l("audio.download-play-amount"),
            sections: [SingleChoiceSection(
                header: l("audio.download-play-amount.description"),
                items: [AudioEnd.juz, .sura, .page]
            )],
            selected: audioPreferences.audioEnd,
            itemText: { $0.name },
            onSelection: { [weak self] item in
                self?.audioPreferences.audioEnd = item
            }
        )
    }

    func navigateToAudioManager() {
        logger.info("Settings: presentAudioDownloads")
        let viewController = audioDownloadsBuilder.build()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func navigateToTranslationsList() {
        logger.info("Settings: presentTranslationsList")
        let viewController = translationsListBuilder.build()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func navigateToReadingSelectors() {
        logger.info("Settings: navigateToReadingSelectors")
        let viewController = readingSelectorBuilder.build()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func shareApp() {
        logger.info("Settings: Share the app.")
        let url = URL(validURL: "https://itunes.apple.com/app/id1118663303")
        let appName = "Quran - by Quran.com - قرآن"

        navigationController?.share([appName, url])
    }

    func writeReview() {
        logger.info("Settings: Navigate to app store to write a review.")
        reviewService.openAppReview()
    }

    func contactUs() {
        logger.info("Settings: presentContactUs")
        let viewController = contactUsService.contactUsController()
        navigationController?.present(viewController, animated: true)
    }

    func navigateToDiagnotics() {
        logger.info("Settings: navigateToDiagnotics")
        let viewController = diagnosticsBuilder.build(navigationController: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func loginToQuranCom() async {
        logger.info("Settings: Login to Quran.com")
        guard let viewController = navigationController else {
            return
        }
        do {
            try await quranProfileService.login(on: viewController)
            // TODO: Replace with the needed UI changes.
            print("Login seems successful")
        } catch {
            logger.error("Failed to login to Quran.com: \(error)")
        }
    }

    // MARK: Private

    private func showSingleChoiceSelector<T: Hashable>(
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
                self?.navigationController?.popViewController(animated: true)
            }
        )
        viewController.title = title
        navigationController?.pushViewController(viewController, animated: true)
    }
}
