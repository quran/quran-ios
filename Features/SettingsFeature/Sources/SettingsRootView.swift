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
            streamingEnabled: $viewModel.streamingEnabled,
            error: $viewModel.error,
            appIcon: viewModel.isAppIconAvailable ? viewModel.appIconOption : nil,
            audioEnd: viewModel.audioEnd.name,
            navigateToAppIcons: { viewModel.navigateToAppIcons() },
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            donate: { viewModel.donate() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() },
            isAuthenticated: viewModel.isAuthenticated,
            loggedInUserEmail: viewModel.currentUserEmail,
            openQuranComProfile: { viewModel.openQuranComProfile() },
            refreshAuthenticationState: { await viewModel.refreshAuthenticationState() },
            loginAction: { await viewModel.loginToQuranCom() },
            logoutAction: { await viewModel.logoutFromQuranCom() }
        )
        #else
        SettingsRootViewUI(
            appearanceMode: appearanceMode,
            streamingEnabled: $viewModel.streamingEnabled,
            error: $viewModel.error,
            appIcon: viewModel.isAppIconAvailable ? viewModel.appIconOption : nil,
            audioEnd: viewModel.audioEnd.name,
            navigateToAppIcons: { viewModel.navigateToAppIcons() },
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
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
    @Binding var streamingEnabled: Bool
    @Binding var error: Error?

    /// The icon iOS shows, or `nil` when the app can't change its icon.
    let appIcon: AppIconOption?
    let audioEnd: String
    let navigateToAppIcons: Action
    let navigateToAudioEndSelector: Action
    let navigateToAudioManager: Action
    let navigateToTranslationsList: Action
    let navigateToReadingSelector: Action
    let donate: Action
    let shareApp: Action
    let writeReview: Action
    let contactUs: Action
    let navigateToDiagnotics: Action

    #if QURAN_SYNC
    let isAuthenticated: Bool
    let loggedInUserEmail: String?
    let openQuranComProfile: AsyncAction
    let refreshAuthenticationState: AsyncAction
    let loginAction: AsyncAction
    let logoutAction: AsyncAction
    #endif

    var body: some View {
        NoorList {
            #if QURAN_SYNC
            NoorBasicSection {
                QuranComAccountCard(
                    isAuthenticated: isAuthenticated,
                    email: loggedInUserEmail,
                    manageAccountAction: { await openQuranComProfile() },
                    signInAction: { await loginAction() },
                    signOutAction: { await logoutAction() }
                )
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
                    title: .text(l("audio.download-play-amount")),
                    subtitle: .init(text: .text(audioEnd), location: .trailing),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToAudioEndSelector() }
                )

                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l("audio.streaming.title"))
                        Text(l("audio.streaming.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(l("audio.streaming.title"), isOn: $streamingEnabled)
                        .labelsHidden()
                }
                .padding(.vertical, 6)

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
        .task { await refreshAuthenticationState() }
        #endif
        .errorAlert(error: $error)
    }

    // MARK: Private

    @ScaledMetric(relativeTo: .body) private var appIconPreviewLength = 30.0
}

#Preview {
    struct Container: View {
        @State var appearanceMode = AppearanceMode.auto
        @State var streamingEnabled = false

        var body: some View {
            #if QURAN_SYNC
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                streamingEnabled: $streamingEnabled,
                error: .constant(nil),
                appIcon: previewAppIcon,
                audioEnd: "Surah",
                navigateToAppIcons: {},
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                donate: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {},
                isAuthenticated: false,
                loggedInUserEmail: nil,
                openQuranComProfile: {},
                refreshAuthenticationState: {},
                loginAction: {},
                logoutAction: {}
            )
            #else
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                streamingEnabled: $streamingEnabled,
                error: .constant(nil),
                appIcon: previewAppIcon,
                audioEnd: "Surah",
                navigateToAppIcons: {},
                navigateToAudioEndSelector: {},
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
