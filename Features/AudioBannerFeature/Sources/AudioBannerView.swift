//
//  AudioBannerView.swift
//
//
//  Created by Mohamed Afifi on 2024-09-23.
//

import Combine
import NoorUI
import SwiftUI
import UIx

struct AudioBannerView: View {
    @StateObject var viewModel: AudioBannerViewModel
    @Environment(\.showToast) private var showToast
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
            more: { viewModel.showAdvancedAudioOptions() },
            setPlaybackRate: { viewModel.updatePlaybackRate(to: $0) }
        )
        AudioBannerViewUI(
            state: viewModel.audioBannerState,
            actions: actions
        )
        .onReceive(viewModel.$toast.compactMap { $0 }) { toast in
            viewModel.toast = nil
            showToast?(Toast(toast.message, action: toast.action, bottomOffset: toastOffset))
        }
        .serializedModalPresentation(request: $viewModel.modalRequest)
        .errorAlert(error: $viewModel.error)
        .taskOnce {
            await viewModel.start()
        }
        .onDisappear {
            ToastPresenter.shared.dismissCurrentToast()
        }
    }
}
