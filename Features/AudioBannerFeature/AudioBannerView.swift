//
//  AudioBannerView.swift
//
//
//  Created by Mohamed Afifi on 2024-09-23.
//

import NoorUI
import SwiftUI
import UIx

struct AudioBannerView: View {
    @StateObject var viewModel: AudioBannerViewModel
    @Environment(\.showToast) private var showToast
    @Environment(\.uikitNavigator) private var navigator
    @ScaledMetric private var toastOffset = 100

    var body: some View {
        let actions = AudioBannerActions(
            play: { viewModel.playFromBanner() },
            pause: { viewModel.pauseFromBanner() },
            resume: { viewModel.resumeFromBanner() },
            stop: { viewModel.stopFromBanner() },
            backward: { viewModel.backwardFromBanner() },
            forward: { viewModel.forwardFromBanner() },
            cancelDownloading: { await viewModel.cancelDownload() },
            reciters: { viewModel.presentReciterList() },
            more: { viewModel.showAdvancedAudioOptions() }
        )
        AudioBannerViewUI(
            state: viewModel.audioBannerState,
            actions: actions
        )
        .onChange(of: viewModel.toast?.message) { _ in
            if let toast = viewModel.toast {
                viewModel.toast = nil
                showToast?(Toast(toast.message, action: toast.action, bottomOffset: toastOffset))
            }
        }
        .onChange(of: viewModel.viewControllerToPresent) { _ in
            if let presentingVC = viewModel.viewControllerToPresent {
                viewModel.viewControllerToPresent = nil
                navigator?.viewController?.present(presentingVC, animated: true)
            }
        }
        .onChange(of: viewModel.dismissPresentedViewController) { _ in
            if viewModel.dismissPresentedViewController {
                viewModel.dismissPresentedViewController = false
                navigator?.viewController?.dismiss(animated: true)
            }
        }
        .errorAlert(error: $viewModel.error)
        .taskOnce {
            await viewModel.start()
        }
        .onDisappear {
            ToastPresenter.shared.dismissCurrentToast()
        }
    }
}
