//
//  SettingsRootView.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct SettingsRootView: View {
    @StateObject var viewModel: SettingsRootViewModel

    var body: some View {
        #if QURAN_SYNC
        SettingsRootViewUI(
            appearanceMode: appearanceMode,
            error: $viewModel.error,
            appIcon: viewModel.isAppIconAvailable ? viewModel.appIconOption : nil,
            navigateToAppIcons: { viewModel.navigateToAppIcons() },
            navigateToAudioPlayback: { viewModel.navigateToAudioPlayback() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            donate: { viewModel.donate() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() },
            accountState: viewModel.accountState,
            syncActivity: viewModel.syncActivity,
            navigateToAccountSync: { viewModel.navigateToAccountSync() },
            observeAuthentication: { await viewModel.observeAuthentication() },
            observeSyncActivity: { await viewModel.observeSyncActivity() },
            syncNow: { viewModel.syncNow() },
            loginAction: { await viewModel.loginToQuranCom() }
        )
        #else
        SettingsRootViewUI(
            appearanceMode: appearanceMode,
            error: $viewModel.error,
            appIcon: viewModel.isAppIconAvailable ? viewModel.appIconOption : nil,
            navigateToAppIcons: { viewModel.navigateToAppIcons() },
            navigateToAudioPlayback: { viewModel.navigateToAudioPlayback() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            donate: { viewModel.donate() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() }
        )
        #endif
    }

    private var appearanceMode: Binding<AppearanceMode> {
        Binding(
            get: { viewModel.appearanceMode },
            set: { viewModel.selectAppearanceMode($0) }
        )
    }
}

private struct SettingsRootViewUI: View {
    // MARK: Internal

    @Binding var appearanceMode: AppearanceMode
    @Binding var error: Error?

    /// The icon iOS shows, or `nil` when the app can't change its icon.
    let appIcon: AppIconOption?
    let navigateToAppIcons: Action
    let navigateToAudioPlayback: Action
    let navigateToAudioManager: Action
    let navigateToTranslationsList: Action
    let navigateToReadingSelector: Action
    let donate: Action
    let shareApp: Action
    let writeReview: Action
    let contactUs: Action
    let navigateToDiagnotics: Action

    #if QURAN_SYNC
    let accountState: QuranComAccountState
    let syncActivity: SyncActivity
    let navigateToAccountSync: Action
    let observeAuthentication: AsyncAction
    let observeSyncActivity: AsyncAction
    let syncNow: Action
    let loginAction: AsyncAction
    #endif

    var body: some View {
        NoorList {
            #if QURAN_SYNC
            NoorBasicSection {
                // Refreshes "2 minutes ago".
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    QuranComAccountCard(
                        accountState: accountState,
                        status: SyncStatusSummary(syncActivity, style: .card),
                        openAccountAction: { navigateToAccountSync() },
                        syncNowAction: { syncNow() },
                        signInAction: { await loginAction() }
                    )
                }
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
            }
            #endif

            NoorBasicSection {
                AppearanceMenu(appearanceMode: $appearanceMode)

                if let appIcon {
                    NoorListItem(
                        image: .init(appIcon: appIcon, length: appIconPreviewLength),
                        title: .text(l("app_icon.title")),
                        subtitle: .init(text: .text(appIcon.name), location: .trailing),
                        accessory: .disclosureIndicator,
                        action: .sync { navigateToAppIcons() }
                    )
                }
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.mushafs),
                    title: .text(l("reading.selector.title")),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToReadingSelector() }
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.audio),
                    title: .text(l("audio.playback.title")),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToAudioPlayback() }
                )

                NoorListItem(
                    image: .init(.downloads),
                    title: .text(lAndroid("audio_manager")),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToAudioManager() }
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.translation),
                    title: .text(lAndroid("prefs_translations")),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToTranslationsList() }
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.heart),
                    title: .text(l("setting.donate")),
                    accessory: .disclosureIndicator,
                    action: .sync { donate() }
                )

                NoorListItem(
                    image: .init(.share),
                    title: .text(l("setting.share_app")),
                    accessory: .disclosureIndicator,
                    action: .sync { shareApp() }
                )

                NoorListItem(
                    image: .init(.star),
                    title: .text(l("setting.write_review")),
                    accessory: .disclosureIndicator,
                    action: .sync { writeReview() }
                )

                NoorListItem(
                    image: .init(.mail),
                    title: .text(l("setting.contact_us")),
                    accessory: .disclosureIndicator,
                    action: .sync { contactUs() }
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.debug),
                    title: .text(l("diagnostics.title")),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToDiagnotics() }
                )
            }
        }
        #if QURAN_SYNC
        .task { await observeAuthentication() }
            .task { await observeSyncActivity() }
        #endif
            .errorAlert(error: $error)
            .noorListIconColumn()
    }

    // MARK: Private

    @ScaledMetric(relativeTo: .body) private var appIconPreviewLength = 30.0
}

#Preview {
    struct Container: View {
        @State var appearanceMode = AppearanceMode.auto

        var body: some View {
            #if QURAN_SYNC
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                error: .constant(nil),
                appIcon: previewAppIcon,
                navigateToAppIcons: {},
                navigateToAudioPlayback: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                donate: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {},
                accountState: .signedOut,
                syncActivity: SyncActivity(),
                navigateToAccountSync: {},
                observeAuthentication: {},
                observeSyncActivity: {},
                syncNow: {},
                loginAction: {}
            )
            #else
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                error: .constant(nil),
                appIcon: previewAppIcon,
                navigateToAppIcons: {},
                navigateToAudioPlayback: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                donate: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {}
            )
            #endif
        }
    }
    return Container()
}

private let previewAppIcon = AppIconOption(
    id: "navy-gold",
    alternateIconName: nil,
    name: "Navy & Gold",
    previewImageName: "app-icon-navy-gold",
    accent: AppIconAccent(light: .systemIndigo, dark: .systemYellow, onDark: .black)
)
