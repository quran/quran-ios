//
//  DefaultAudioBannerView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import QueuePlayer
import UIKit

private let viewHeight: CGFloat = 48

class DefaultAudioBannerView: UIView, AudioBannerView {

    weak var delegate: AudioBannerViewDelegate?

    private var bottomConstraint: NSLayoutConstraint?

    let visualEffect = ThemedVisualEffectView()

    let qariView = AudioQariBarView()
    let playView = AudioPlayBarView()
    let downloadView = AudioDownloadingBarView()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTouchesBegan?()
    }

    var onTouchesBegan: (() -> Void)?

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    func setUp() {
        backgroundColor = nil

        addAutoLayoutSubview(visualEffect)
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
        addAutoLayoutSubview(topBorder)
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

    fileprivate func setUpQariView() {
        [qariView.playButton,
            qariView.backgroundButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), for: .touchDown) }

        qariView.playButton.addTarget(self, action: #selector(qariPlayTapped), for: .touchUpInside)
        qariView.backgroundButton.addTarget(self, action: #selector(qariTapped), for: .touchUpInside)
    }

    fileprivate func setUpPlayView() {
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

    fileprivate func setUpDownloadView() {
        [downloadView.cancelButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), for: .touchDown) }

        downloadView.cancelButton.addTarget(self, action: #selector(cancelDownloadTapped), for: .touchUpInside)
    }

    func hideAllControls() {
        [qariView, playView, downloadView].forEach { $0.alpha = 0 }
    }

    func setQari(name: String, image: UIImage?) {

        qariView.imageView.image = image
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

    fileprivate func hideAllExcept(_ view: UIView) {
        UIView.animate(withDuration: 0.25, animations: {
            for subview in [self.qariView, self.playView, self.downloadView] {
                subview.alpha = subview == view ? 1 : 0
            }
        })
    }

    @objc
    fileprivate func buttonTouchesBegan() {
        onTouchesBegan?()
    }

    @objc
    fileprivate func qariTapped() {
        delegate?.onQariTapped()
    }

    @objc
    fileprivate func qariPlayTapped() {
        delegate?.onPlayTapped()
    }

    @objc
    fileprivate func stopPlayingTapped() {
        delegate?.onStopTapped()
    }

    @objc
    fileprivate func onPauseResumeTapped() {
        delegate?.onPauseResumeTapped()
    }

    @objc
    fileprivate func previousTapped() {
        delegate?.onBackwardTapped()
    }

    @objc
    fileprivate func nextTapped() {
        delegate?.onForwardTapped()
    }

    @objc
    fileprivate func moreTapped() {
        delegate?.onMoreTapped()
    }

    @objc
    fileprivate func cancelDownloadTapped() {
        delegate?.onCancelDownloadTapped()
    }
}
