//
//  SettingsRootViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-06-26.
//

import Analytics
import AppIconFeature
import AudioDownloadsFeature
import Combine
import FeaturesSupport
#if QURAN_SYNC
import AuthenticationClient
import LegacyDataMigration
import MobileSync
#endif
import NoorUI
import ReadingSelectorFeature
import SafariServices
import SettingsService
import TranslationsFeature
import UIKit
import VLogging

@MainActor
final class SettingsRootViewModel: ObservableObject {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        analytics: AnalyticsLibrary,
        reviewService: ReviewService,
        authenticationClient: any AuthenticationClient,
        quranDataService: MobileSyncDataService,
        legacyDataImportCoordinator: LegacyDataImportCoordinator,
        audioPlaybackBuilder: AudioPlaybackBuilder,
        audioDownloadsBuilder: AudioDownloadsBuilder,
        translationsListBuilder: TranslationsListBuilder,
        readingSelectorBuilder: ReadingSelectorBuilder,
        diagnosticsBuilder: DiagnosticsBuilder,
        appIconService: AppIconService,
        appIconBuilder: AppIconBuilder,
        accountSyncBuilder: AccountSyncBuilder,
        navigationController: UINavigationController
    ) {
        appearanceMode = themeService.appearanceMode
        isAppIconAvailable = appIconService.isAvailable
        appIconOption = appIconService.currentOption
        self.analytics = analytics
        self.reviewService = reviewService
        self.authenticationClient = authenticationClient
        self.quranDataService = quranDataService
        self.legacyDataImportCoordinator = legacyDataImportCoordinator
        self.audioPlaybackBuilder = audioPlaybackBuilder
        self.audioDownloadsBuilder = audioDownloadsBuilder
        self.translationsListBuilder = translationsListBuilder
        self.readingSelectorBuilder = readingSelectorBuilder
        self.diagnosticsBuilder = diagnosticsBuilder
        self.appIconBuilder = appIconBuilder
        self.accountSyncBuilder = accountSyncBuilder
        self.navigationController = navigationController

        themeService.appearanceModePublisher.assign(to: &$appearanceMode)
        appIconService.currentOptionPublisher.assign(to: &$appIconOption)
    }
    #else
    init(
        analytics: AnalyticsLibrary,
        reviewService: ReviewService,
        audioPlaybackBuilder: AudioPlaybackBuilder,
        audioDownloadsBuilder: AudioDownloadsBuilder,
        translationsListBuilder: TranslationsListBuilder,
        readingSelectorBuilder: ReadingSelectorBuilder,
        diagnosticsBuilder: DiagnosticsBuilder,
        appIconService: AppIconService,
        appIconBuilder: AppIconBuilder,
        navigationController: UINavigationController
    ) {
        appearanceMode = themeService.appearanceMode
        isAppIconAvailable = appIconService.isAvailable
        appIconOption = appIconService.currentOption
        self.analytics = analytics
        self.reviewService = reviewService
        self.audioPlaybackBuilder = audioPlaybackBuilder
        self.audioDownloadsBuilder = audioDownloadsBuilder
        self.translationsListBuilder = translationsListBuilder
        self.readingSelectorBuilder = readingSelectorBuilder
        self.diagnosticsBuilder = diagnosticsBuilder
        self.appIconBuilder = appIconBuilder
        self.navigationController = navigationController

        themeService.appearanceModePublisher.assign(to: &$appearanceMode)
        appIconService.currentOptionPublisher.assign(to: &$appIconOption)
    }
    #endif

    // MARK: Internal

    let analytics: AnalyticsLibrary
    let reviewService: ReviewService
    let audioPlaybackBuilder: AudioPlaybackBuilder
    let audioDownloadsBuilder: AudioDownloadsBuilder
    let translationsListBuilder: TranslationsListBuilder
    let readingSelectorBuilder: ReadingSelectorBuilder
    let diagnosticsBuilder: DiagnosticsBuilder
    let appIconBuilder: AppIconBuilder

    /// Whether the app can change its Home Screen icon. The App Icon row hides otherwise.
    let isAppIconAvailable: Bool

    let contactUsService = ContactUsService()
    let themeService = ThemeService.shared

    weak var navigationController: UINavigationController?

    @Published var error: Error? = nil
    #if QURAN_SYNC
    @Published var accountState: QuranComAccountState = .unknown
    @Published private(set) var syncActivity = SyncActivity()
    #endif

    @Published var appearanceMode: AppearanceMode {
        didSet {
            themeService.appearanceMode = appearanceMode
        }
    }

    /// The icon iOS shows for the app.
    @Published private(set) var appIconOption: AppIconOption

    func selectAppearanceMode(_ mode: AppearanceMode) {
        guard mode != appearanceMode else {
            return
        }
        logger.info("Settings: appearance mode changed to \(mode)")
        analytics.changeAppearanceMode(mode)
        appearanceMode = mode
    }

    func navigateToAppIcons() {
        logger.info("Settings: navigateToAppIcons")
        let viewController = appIconBuilder.build(source: .settings)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func navigateToAudioPlayback() {
        logger.info("Settings: navigateToAudioPlayback")
        let viewController = audioPlaybackBuilder.build(navigationController: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
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

    #if QURAN_SYNC
    var loggedInUser: MobileSyncUser? {
        if case .signedIn(let user) = accountState {
            user
        } else {
            nil
        }
    }

    var currentUserEmail: String? {
        loggedInUser?.email
    }

    func navigateToAccountSync() {
        logger.info("Settings: navigateToAccountSync")
        let viewController = accountSyncBuilder.build(
            user: loggedInUser,
            signOut: { [weak self] in try await self?.signOutOfQuranCom(from: .accountSync) },
            navigationController: navigationController
        )
        navigationController?.pushViewController(viewController, animated: true)
    }
    #endif

    func navigateToDiagnotics() {
        logger.info("Settings: navigateToDiagnotics")
        let viewController = diagnosticsBuilder.build(navigationController: navigationController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    #if QURAN_SYNC
    /// Keeps the account card on the signed-in user until the task is cancelled, such as after signing in or
    /// when a background token refresh updates the profile, and restores the session alongside.
    ///
    /// The card's state comes from these updates, so it stays unknown until the first one, which MobileSync
    /// yields once it has read the stored session, without waiting for the restore's token refresh. When they
    /// fail before it, the card shows the restored state instead. After any other error, the card stops updating
    /// until Settings appears again.
    func observeAuthentication() async {
        async let restoredState = restoreAuthentication()
        let updatesFailed = await observeLoggedInUser()
        let state = await restoredState
        // The restore returns once the session is known, unlike `authenticationState` while MobileSync is
        // still reading it.
        if updatesFailed, accountState == .unknown {
            accountState = state == .authenticated ? .signedIn(loggedInUser) : .signedOut
        }
    }

    /// Follows the sync status, runs and held items for the account card until the task is cancelled.
    func observeSyncActivity() async {
        for await change in SyncActivity.changes(of: quranDataService) {
            syncActivity.apply(change)
        }
    }

    func syncNow() {
        logger.info("Quran Sync: Sync now from Settings")
        quranDataService.triggerSync(immediately: true)
    }

    func loginToQuranCom() async {
        guard let viewController = navigationController else {
            return
        }

        analytics.quranSyncSignIn(from: .settings)
        logger.info("Quran Sync: starting sign in from Settings")
        do {
            try await authenticationClient.login(on: viewController)
            let state = await authenticationClient.authenticationState
            logger.info("Quran Sync: sign in completed from Settings. State: \(state)")
            // While observing, the updates show the card signed in together with the user.
            if runningAuthenticationObservations == 0 {
                accountState = state == .authenticated ? .signedIn(loggedInUser) : .signedOut
            }
        } catch AuthenticationClientError.cancelled {
            logger.info("Quran Sync: sign in cancelled from Settings")
            return
        } catch {
            logger.error("Failed to login to Quran.com: \(error)")
            self.error = error
        }
    }

    /// Signs out for the Account & Sync screen, which confirms first and shows the error.
    func signOutOfQuranCom(from source: QuranSyncAuthenticationSource) async throws {
        analytics.quranSyncSignOut(from: source)
        logger.info("Quran Sync: starting sign out from \(source)")
        // Stop legacy import before the logout reset, so legacy data never returns afterwards.
        await legacyDataImportCoordinator.disable()
        do {
            try await authenticationClient.logout()
            accountState = .signedOut
            logger.info("Quran Sync: sign out succeeded from \(source)")
        } catch {
            logger.error("Failed to logout from Quran.com: \(error)")
            throw error
        }
    }
    #endif

    // MARK: Private

    #if QURAN_SYNC
    private let accountSyncBuilder: AccountSyncBuilder
    private let quranDataService: MobileSyncDataService
    private var authenticationClient: any AuthenticationClient
    private let legacyDataImportCoordinator: LegacyDataImportCoordinator

    /// How many `observeAuthentication()` calls are following the updates. A count, not a flag, because
    /// SwiftUI can start the next `.task` before the cancelled one ends.
    private var runningAuthenticationObservations = 0

    /// - Returns: Whether the updates failed with an error other than cancellation.
    private func observeLoggedInUser() async -> Bool {
        runningAuthenticationObservations += 1
        defer { runningAuthenticationObservations -= 1 }
        do {
            for try await user in authenticationClient.loggedInUserUpdates {
                await showLoggedInUser(user)
            }
        } catch is CancellationError {
            return false
        } catch {
            logger.error("Quran Sync: failed to observe the signed-in user from Settings: \(error)")
            return true
        }
        return false
    }

    /// Refreshes the session's tokens. The card doesn't wait for it: the updates bring the session first.
    private func restoreAuthentication() async -> AuthenticationState {
        let restoredState = await authenticationClient.safelyRestoreState()
        logger.info("Quran Sync: restored authentication from Settings. State: \(restoredState)")
        return restoredState
    }

    /// The authentication state decides whether the user is signed in, because a nil user can also be
    /// a signed-in session whose profile isn't known yet. That keeps the last known profile.
    private func showLoggedInUser(_ user: MobileSyncUser?) async {
        guard await authenticationClient.authenticationState == .authenticated else {
            accountState = .signedOut
            return
        }
        if let user {
            accountState = .signedIn(user)
        } else if case .signedIn = accountState {
            return
        } else {
            accountState = .signedIn(nil)
        }
    }
    #endif
}

#if QURAN_SYNC
/// What the Quran.com account card shows.
enum QuranComAccountState: Equatable {
    /// Not known yet: MobileSync hasn't read the stored session.
    case unknown
    case signedOut
    /// The user is nil for a signed-in session whose profile isn't known yet.
    case signedIn(MobileSyncUser?)
}
#endif

private extension AnalyticsLibrary {
    func changeAppearanceMode(_ mode: AppearanceMode) {
        logEvent("ChangeAppearanceMode", value: mode.description)
    }
}
