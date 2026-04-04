//
//  SettingsRootViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-06-26.
//

import Analytics
import AudioDownloadsFeature
import AuthenticationClient
import Combine
import Localization
import NoorUI
import QuranAudio
import QuranAudioKit
import ReadingSelectorFeature
import SafariServices
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
        authenticationClient: (any AuthenticationClient)?,
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
        self.authenticationClient = authenticationClient
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
    let audioDownloadsBuilder: AudioDownloadsBuilder
    let translationsListBuilder: TranslationsListBuilder
    let readingSelectorBuilder: ReadingSelectorBuilder
    let diagnosticsBuilder: DiagnosticsBuilder

    let contactUsService = ContactUsService()
    let themeService = ThemeService.shared
    let audioPreferences = AudioPreferences.shared

    weak var navigationController: UINavigationController?

    @Published var audioEnd: AudioEnd
    @Published var error: Error? = nil
    @Published var isAuthenticated: Bool = false
    @Published var currentUserEmail: String? = nil

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
                items: [AudioEnd.juz, .sura, .page, .quran]
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

    func donate() {
        logger.info("Settings: Open donation page.")
        let url = URL(validURL: "https://give.quran.foundation/ios")
        let viewController = SFSafariViewController(url: url)
        navigationController?.present(viewController, animated: true)
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

    func openQuranComProfile() {
        logger.info("Settings: Open Quran.com profile.")
        let url = URL(validURL: "https://quran.com/profile")
        let viewController = SFSafariViewController(url: url)
        navigationController?.present(viewController, animated: true)
    }

    func navigateToDiagnotics() {
        logger.info("Settings: navigateToDiagnotics")
        let viewController = diagnosticsBuilder.build(navigationController: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func refreshAuthenticationState() async {
        guard let authenticationClient else {
            isAuthenticated = false
            currentUserEmail = nil
            return
        }

        do {
            isAuthenticated = try await authenticationClient.restoreState() == .authenticated
        } catch {
            isAuthenticated = await authenticationClient.authenticationState == .authenticated
        }
        currentUserEmail = isAuthenticated ? await authenticationClient.currentUserEmail : nil
    }

    func loginToQuranCom() async {
        guard let viewController = navigationController else {
            return
        }

        do {
            let authenticationClient = try requireAuthenticationClient()
            try await authenticationClient.login(on: viewController)
            isAuthenticated = true
            currentUserEmail = await authenticationClient.currentUserEmail
        } catch {
            logger.error("Failed to login to Quran.com: \(error)")
            self.error = error
        }
    }

    func logoutFromQuranCom() async {
        do {
            let authenticationClient = try requireAuthenticationClient()
            try await authenticationClient.logout()
            isAuthenticated = false
            currentUserEmail = nil
        } catch {
            logger.error("Failed to logout from Quran.com: \(error)")
            self.error = error
        }
    }

    // MARK: Private

    private let authenticationClient: (any AuthenticationClient)?

    private func requireAuthenticationClient() throws -> any AuthenticationClient {
        guard let authenticationClient else {
            throw AuthenticationClientError.clientIsNotAuthenticated(nil)
        }
        return authenticationClient
    }

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
