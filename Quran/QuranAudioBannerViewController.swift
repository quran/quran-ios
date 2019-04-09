//
//  QuranAudioBannerViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift
import UIKit

private let viewHeight: CGFloat = 48

protocol QuranAudioBannerPresentableListener: class {
    func onPlayTapped()
    func onPauseResumeTapped()
    func onStopTapped()
    func onForwardTapped()
    func onBackwardTapped()
    func onMoreTapped()
    func onQariTapped()
    func onCancelDownloadTapped()

    func onTouchesBegan()

    func didDismissPopover()
}

final class QuranAudioBannerViewController: UIViewController, QuranAudioBannerPresentable,
                                QuranAudioBannerViewControllable, PopoverPresenterDelegate {

    private lazy var qariListPresenter = QariListPresenter(delegate: self)

    weak var listener: QuranAudioBannerPresentableListener?

    private var bottomConstraint: NSLayoutConstraint?

    private let visualEffect = ThemedVisualEffectView()

    private let qariView = AudioQariBarView()
    private let playView = AudioPlayBarView()
    private let downloadView = AudioDownloadingBarView()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        listener?.onTouchesBegan()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        view.addAutoLayoutSubview(visualEffect)
        visualEffect.vc.edges()

        let contentView = UIView()
        visualEffect.contentView.addAutoLayoutSubview(contentView)
        contentView.vc
            .height(by: viewHeight)
            .horizontalEdges()
            .top()
        bottomConstraint = contentView.vc.bottom(usesMargins: true).constraint

        let borderHeight: CGFloat = UIScreen.main.scale < 2 ? 1 : 0.5

        let topBorder = ThemedView()
        topBorder.kind = Theme.Kind.separator
        topBorder.vc.height(by: borderHeight)
        view.addAutoLayoutSubview(topBorder)
        topBorder.vc
            .horizontalEdges()
            .top(by: -borderHeight)

        visualEffect.contentView.addAutoLayoutSubview(qariView)
        for view in [playView, downloadView] {
            contentView.addAutoLayoutSubview(view)
        }

        for view in [qariView, playView, downloadView] {
            view.vc.edges()

            view.backgroundColor = nil
            view.alpha = 0
        }

        setUpQariView()
        setUpPlayView()
        setUpDownloadView()
    }

    private func setUpQariView() {
        [qariView.playButton,
         qariView.backgroundButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), for: .touchDown) }

        qariView.playButton.addTarget(self, action: #selector(qariPlayTapped), for: .touchUpInside)
        qariView.backgroundButton.addTarget(self, action: #selector(qariTapped), for: .touchUpInside)
    }

    private func setUpPlayView() {
        [playView.stopButton,
         playView.pauseResumeButton,
         playView.nextButton,
         playView.previousButton,
         playView.moreButton].forEach { $0?.addTarget(self, action: #selector(buttonTouchesBegan), for: .touchDown) }

        playView.stopButton.addTarget(self, action: #selector(stopPlayingTapped), for: .touchUpInside)
        playView.pauseResumeButton.addTarget(self, action: #selector(onPauseResumeTapped), for: .touchUpInside)
        playView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        playView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        playView.moreButton?.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
    }

    private func setUpDownloadView() {
        [downloadView.cancelButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), for: .touchDown) }

        downloadView.cancelButton.addTarget(self, action: #selector(cancelDownloadTapped), for: .touchUpInside)
    }

    func hideAllControls() {
        loadViewIfNeeded()
        [qariView, playView, downloadView].forEach { $0.alpha = 0 }
    }

    func setQari(name: String, imageName: String) {
        qariView.imageView.image = UIImage(named: imageName)
        qariView.titleLabel.text = name

        hideAllExcept(qariView)
    }

    func setDownloading(_ progress: Float) {

        downloadView.progressView.progress = progress

        hideAllExcept(downloadView)
    }

    func setPlaying() {
        playView.pauseResumeButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: UIControl.State())

        hideAllExcept(playView)
    }

    func setPaused() {
        playView.pauseResumeButton.setImage(#imageLiteral(resourceName: "ic_play"), for: UIControl.State())

        hideAllExcept(playView)
    }

    private func hideAllExcept(_ view: UIView) {
        UIView.animate(withDuration: 0.25, animations: {
            for subview in [self.qariView, self.playView, self.downloadView] {
                subview.alpha = subview == view ? 1 : 0
            }
        })
    }

    @objc
    private func buttonTouchesBegan() {
        listener?.onTouchesBegan()
    }

    @objc
    private func qariTapped() {
        listener?.onQariTapped()
    }

    @objc
    private func qariPlayTapped() {
        listener?.onPlayTapped()
    }

    @objc
    private func stopPlayingTapped() {
        listener?.onStopTapped()
    }

    @objc
    private func onPauseResumeTapped() {
        listener?.onPauseResumeTapped()
    }

    @objc
    private func previousTapped() {
        listener?.onBackwardTapped()
    }

    @objc
    private func nextTapped() {
        listener?.onForwardTapped()
    }

    @objc
    private func moreTapped() {
        listener?.onMoreTapped()
    }

    @objc
    private func cancelDownloadTapped() {
        listener?.onCancelDownloadTapped()
    }

    func presentQariList(_ viewController: ViewControllable) {
        qariListPresenter.present(presenting: self, presented: viewController.uiviewController, pointingTo: view)
    }

    func didDismissPopover() {
        listener?.didDismissPopover()
    }
}
