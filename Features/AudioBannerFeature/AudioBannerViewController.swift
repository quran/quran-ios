//
//  AudioBannerViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AdvancedAudioOptionsFeature
import Combine
import Localization
import NoorUI
import QuranAudio
import ReciterListFeature
import UIKit
import VLogging

private let viewHeight: CGFloat = 48

final class AudioBannerViewController: UIViewController, AdvancedAudioOptionsListener, ReciterListListener {
    // MARK: Lifecycle

    init(
        viewModel: AudioBannerViewModel,
        reciterListBuilder: ReciterListBuilder,
        advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder
    ) {
        self.viewModel = viewModel
        self.reciterListBuilder = reciterListBuilder
        self.advancedAudioOptionsBuilder = advancedAudioOptionsBuilder
        super.init(nibName: nil, bundle: nil)
        viewModel.internalActions = AudioBannerViewModelInternalActions(
            showError: { [weak self] in self?.showErrorAlert(error: $0) },
            playingStarted: { [weak self] in self?.playingStarted() },
            willStartDownloading: { [weak self] in self?.willStartDownloading() }
        )

        Task {
            await viewModel.start()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil
        view.layer.shadowOpacity = 0.6
        view.layer.shadowRadius = 2
        view.layer.shadowOffset = .zero
        view.layer.shadowColor = UIColor.systemGray.cgColor

        view.addAutoLayoutSubview(visualEffect)
        visualEffect.vc.edges()

        let contentView = UIView()
        visualEffect.contentView.addAutoLayoutSubview(contentView)
        contentView.vc
            .height(by: viewHeight)
            .horizontalEdges()
            .top()
        bottomConstraint = contentView.vc.bottom(usesMargins: true).constraint

        visualEffect.contentView.addAutoLayoutSubview(reciterView)
        for view in [playView, downloadView] {
            contentView.addAutoLayoutSubview(view)
        }

        for view in [reciterView, playView, downloadView] {
            view.vc.edges()

            view.backgroundColor = nil
            view.alpha = 0
        }

        setUpReciterView()
        setUpPlayView()
        setUpDownloadView()
        hideAllControls()

        listenToPlayingStateChanges()
    }

    func hideAllControls() {
        logger.info("AudioBanner: hideAllControls")
        loadViewIfNeeded()
        [reciterView, playView, downloadView].forEach { $0.alpha = 0 }
    }

    func setReciter(name: String) {
        reciterView.imageView.isHidden = true
        reciterView.titleLabel.text = name

        hideAllExcept(reciterView)
    }

    func setDownloading(_ progress: Float) {
        logger.info("AudioBanner: downloading \(progress)")
        downloadView.progressView.progress = progress

        hideAllExcept(downloadView)
    }

    func setPlaying() {
        logger.info("AudioBanner: setPlaying")
        playView.pauseResumeButton.setImage(.symbol("pause.fill"), for: UIControl.State())

        hideAllExcept(playView)
    }

    func setPaused() {
        logger.info("AudioBanner: setPaused")
        playView.pauseResumeButton.setImage(.symbol("play.fill"), for: UIControl.State())

        hideAllExcept(playView)
    }

    func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        logger.info("AudioBanner: updateAudioOptions")
        viewModel.updateAudioOptions(to: newOptions)
    }

    func dismissAudioOptions() {
        logger.info("AudioBanner: dismiss advanced audio options")
        dismiss(animated: true)
    }

    // MARK: - Reciter List

    func onSelectedReciterChanged(to reciter: Reciter) {
        logger.info("AudioBanner: onSelectedReciterChanged to \(reciter.id)")
        viewModel.onSelectedReciterChanged(to: reciter)
    }

    func dismissReciterList() {
        logger.info("AudioBanner: dismiss reciters list")
        dismiss(animated: true)
    }

    // MARK: Private

    private let viewModel: AudioBannerViewModel
    private let reciterListBuilder: ReciterListBuilder
    private let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder
    private var cancellables: Set<AnyCancellable> = []

    private var bottomConstraint: NSLayoutConstraint?

    private let visualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    private let reciterView = AudioReciterBarView()
    private let playView = AudioPlayBarView()
    private let downloadView = AudioDownloadingBarView()

    private func listenToPlayingStateChanges() {
        viewModel.$playingState.sink { [weak self] playingState in
            switch playingState {
            case .playing: self?.setPlaying()
            case .paused: self?.setPaused()
            case .stopped: self?.showReciterView()
            case .downloading(let progress): self?.setDownloading(progress)
            }
        }
        .store(in: &cancellables)
    }

    private func setUpReciterView() {
        reciterView.playButton.addTarget(self, action: #selector(reciterPlayTapped), for: .touchUpInside)
        reciterView.backgroundButton.addTarget(self, action: #selector(reciterTapped), for: .touchUpInside)
        reciterView.moreButton?.addTarget(self, action: #selector(showAdvancedAudioOptionsNotPlaying), for: .touchUpInside)
        reciterView.backgroundButton.accessibilityLabel = "Reciter banner"
    }

    private func setUpPlayView() {
        playView.stopButton.addTarget(self, action: #selector(stopPlayingTapped), for: .touchUpInside)
        playView.pauseResumeButton.addTarget(self, action: #selector(onPauseResumeTapped), for: .touchUpInside)
        playView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        playView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        playView.moreButton?.addTarget(self, action: #selector(showAdvancedAudioOptions), for: .touchUpInside)
    }

    private func setUpDownloadView() {
        downloadView.cancelButton.addTarget(self, action: #selector(cancelDownloadTapped), for: .touchUpInside)
    }

    private func showReciterView() {
        logger.info("AudioBanner: show reciter view \(String(describing: viewModel.selectedReciter?.id))")
        guard let selectedReciter = viewModel.selectedReciter else {
            logger.info("AudioBanner: No reciter selected")
            return
        }
        setReciter(name: selectedReciter.localizedName)
        viewModel.showReciterView()
    }

    private func hideAllExcept(_ view: UIView) {
        UIView.animate(withDuration: 0.25, animations: {
            for subview in [self.reciterView, self.playView, self.downloadView] {
                subview.alpha = subview == view ? 1 : 0
            }
        })
    }

    @objc
    private func reciterTapped() {
        logger.info("AudioBanner: reciters button tapped. State: \(viewModel.playingState)")
        let viewController = reciterListBuilder.build(withListener: self)
        presentReciterList(viewController)
    }

    @objc
    private func reciterPlayTapped() {
        viewModel.onPlayTapped()
    }

    @objc
    private func stopPlayingTapped() {
        viewModel.onStopTapped()
    }

    @objc
    private func onPauseResumeTapped() {
        viewModel.onPauseResumeTapped()
    }

    @objc
    private func previousTapped() {
        viewModel.onBackwardTapped()
    }

    @objc
    private func nextTapped() {
        viewModel.onForwardTapped()
    }

    @objc
    private func cancelDownloadTapped() {
        Task {
            await viewModel.cancelDownload()
        }
    }

    // MARK: - Alerts

    private func willStartDownloading() {
        if let audioRange = viewModel.audioRange {
            let message = audioMessage("audio.downloading.message", audioRange: audioRange)
            showDownloadingMessage(message)
        }
    }

    private func showDownloadingMessage(_ message: String) {
        let alert = AlertViewController(message: message)
        alert.show(autoHideAfter: 2)
    }

    private func playingStarted() {
        if let audioRange = viewModel.audioRange {
            let message = audioMessage("audio.playing.message", audioRange: audioRange)
            showPlayingMessage(message)
        }
    }

    private func audioMessage(_ format: String, audioRange: AudioBannerViewModel.AudioRange) -> String {
        lFormat(format, audioRange.start.localizedName, audioRange.end.localizedName)
    }

    private func showPlayingMessage(_ message: String) {
        let alert = AlertViewController(message: message)
        alert.addAction(l("audio.playing.action.modify")) { [weak self] in
            self?.showAdvancedAudioOptions()
        }
        alert.addAction(lAndroid("dialog_ok"))
        alert.show(autoHideAfter: 3)
    }

    // MARK: - Advanced Audio Options

    @objc
    private func showAdvancedAudioOptions() {
        logger.info("AudioBanner: more button tapped. State: \(viewModel.playingState)")
        guard let options = viewModel.advancedAudioOptions else {
            logger.info("AudioBanner: showAdvancedAudioOptions couldn't construct advanced audio options")
            return
        }
        let viewController = advancedAudioOptionsBuilder.build(withListener: self, options: options)
        present(viewController, animated: true)
    }

    @objc
    private func showAdvancedAudioOptionsNotPlaying() {
        logger.info("AudioBanner: more button tapped. State: \(viewModel.playingState)")
        guard let options = viewModel.advancedAudioOptionsNotPlaying else {
            logger.info("AudioBanner: showAdvancedAudioOptionsNotPlaying couldn't construct advanced audio options")
            return
        }
        let viewController = advancedAudioOptionsBuilder.build(withListener: self, options: options)
        present(viewController, animated: true)
    }

    private func presentReciterList(_ viewController: UIViewController) {
        let reciterNavigation = ReciterNavigationController(rootViewController: viewController)
        present(reciterNavigation, animated: true, completion: nil)
    }
}
