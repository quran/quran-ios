//
//  DefaultAudioBannerView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class DefaultAudioBannerView: UIView, AudioBannerView {

    weak var delegate: AudioBannerViewDelegate?

    let visualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

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
        addHeightConstraint(48)

        addAutoLayoutSubview(visualEffect)
        pinParentAllDirections(visualEffect)

        let borderHeight: CGFloat = UIScreen.main.scale < 2 ? 1 : 0.5

        let topBorder = UIView()
        topBorder.backgroundColor = UIColor.lightGray
        topBorder.addHeightConstraint(borderHeight)
        addAutoLayoutSubview(topBorder)
        pinParentHorizontal(topBorder)
        addParentTopConstraint(topBorder, value: -borderHeight)

        for view in [qariView, playView, downloadView] {
            visualEffect.contentView.addAutoLayoutSubview(view)
            visualEffect.contentView.pinParentAllDirections(view)
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
            playView.repeatButton].forEach { $0?.addTarget(self, action: #selector(buttonTouchesBegan), for: .touchDown) }

        playView.stopButton.addTarget(self, action: #selector(stopPlayingTapped), for: .touchUpInside)
        playView.pauseResumeButton.addTarget(self, action: #selector(onPauseResumeTapped), for: .touchUpInside)
        playView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        playView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        playView.repeatButton?.addTarget(self, action: #selector(repeatTapped), for: .touchUpInside)
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
        playView.pauseResumeButton.setImage(UIImage(named: "ic_pause"), for: UIControlState())

        hideAllExcept(playView)
    }

    func setPaused() {

        playView.pauseResumeButton.setImage(UIImage(named: "ic_play"), for: UIControlState())

        hideAllExcept(playView)
    }

    func setRepeatCount(_ count: AudioRepeat) {

        let formatter = NumberFormatter()
        let text: String
        switch count {
        case .none:
            text = ""
        case .once:
            text = formatter.format(1)
        case .twice:
            text = formatter.format(2)
        case .threeTimes:
            text = formatter.format(3)
        case .infinite:
            text = "∞"
        }
        playView.repeatCountLabel?.text = text
    }

    fileprivate func hideAllExcept(_ view: UIView) {
        UIView.animate(withDuration: 0.25, animations: {
            for subview in [self.qariView, self.playView, self.downloadView] {
                subview.alpha = subview == view ? 1 : 0
            }
        })
    }

    @objc fileprivate func buttonTouchesBegan() {
        onTouchesBegan?()
    }

    @objc fileprivate func qariTapped() {
        delegate?.onQariTapped()
    }

    @objc fileprivate func qariPlayTapped() {
        delegate?.onPlayTapped()
    }

    @objc fileprivate func stopPlayingTapped() {
        delegate?.onStopTapped()
    }

    @objc fileprivate func onPauseResumeTapped() {
        delegate?.onPauseResumeTapped()
    }

    @objc fileprivate func previousTapped() {
        delegate?.onBackwardTapped()
    }

    @objc fileprivate func nextTapped() {
        delegate?.onForwardTapped()
    }

    @objc fileprivate func repeatTapped() {
        delegate?.onRepeatTapped()
    }

    @objc fileprivate func cancelDownloadTapped() {
        delegate?.onCancelDownloadTapped()
    }
}
