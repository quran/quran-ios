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

    let visualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))

    let qariView = AudioQariBarView()
    let playView = AudioPlayBarView()
    let downloadView = AudioDownloadingBarView()

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        onTouchesBegan?()
    }

    var onTouchesBegan: (() -> Void)?

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
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

        let topBorder = UIView()
        topBorder.backgroundColor = UIColor.lightGrayColor()
        topBorder.addHeightConstraint(0.5)
        addAutoLayoutSubview(topBorder)
        pinParentHorizontal(topBorder)
        addParentTopConstraint(topBorder, value: -0.5)

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

    private func setUpQariView() {
        [qariView.playButton,
            qariView.backgroundButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), forControlEvents: .TouchDown) }

        qariView.playButton.addTarget(self, action: #selector(qariPlayTapped), forControlEvents: .TouchUpInside)
        qariView.backgroundButton.addTarget(self, action: #selector(qariTapped), forControlEvents: .TouchUpInside)
    }

    private func setUpPlayView() {
        [playView.stopButton,
            playView.pauseResumeButton,
            playView.nextButton,
            playView.previousButton,
            playView.repeatButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), forControlEvents: .TouchDown) }

        playView.stopButton.addTarget(self, action: #selector(stopPlayingTapped), forControlEvents: .TouchUpInside)
        playView.pauseResumeButton.addTarget(self, action: #selector(onPauseResumeTapped), forControlEvents: .TouchUpInside)
        playView.nextButton.addTarget(self, action: #selector(nextTapped), forControlEvents: .TouchUpInside)
        playView.previousButton.addTarget(self, action: #selector(previousTapped), forControlEvents: .TouchUpInside)
        playView.repeatButton.addTarget(self, action: #selector(repeatTapped), forControlEvents: .TouchUpInside)
    }

    private func setUpDownloadView() {
        [downloadView.cancelButton].forEach { $0.addTarget(self, action: #selector(buttonTouchesBegan), forControlEvents: .TouchDown) }

        downloadView.cancelButton.addTarget(self, action: #selector(cancelDownloadTapped), forControlEvents: .TouchUpInside)
    }

    func hideAllControls() {
        [qariView, playView, downloadView].forEach { $0.alpha = 0 }
    }

    func setQari(name name: String, image: UIImage?) {

        qariView.imageView.image = image
        qariView.titleLabel.text = name

        hideAllExcept(qariView)
    }

    func setDownloading(progress: Float) {

        downloadView.progressView.progress = progress

        hideAllExcept(downloadView)
    }

    func setPlaying() {
        playView.pauseResumeButton.setImage(UIImage(named: "ic_pause"), forState: .Normal)

        hideAllExcept(playView)
    }

    func setPaused() {

        playView.pauseResumeButton.setImage(UIImage(named: "ic_play"), forState: .Normal)

        hideAllExcept(playView)
    }

    func setRepeatCount(count: AudioRepeat) {

        let formatter = NSNumberFormatter()
        let text: String
        switch count {
        case .None:
            text = ""
        case .Once:
            text = formatter.format(1)
        case .Twice:
            text = formatter.format(2)
        case .ThreeTimes:
            text = formatter.format(3)
        case .Infinite:
            text = "∞"
        }
        playView.repeatCountLabel.text = text
    }

    private func hideAllExcept(view: UIView) {
        UIView.animateWithDuration(0.25) {
            for subview in [self.qariView, self.playView, self.downloadView] {
                subview.alpha = subview == view ? 1 : 0
            }
        }
    }

    @objc private func buttonTouchesBegan() {
        onTouchesBegan?()
    }

    @objc private func qariTapped() {
        delegate?.onQariTapped()
    }

    @objc private func qariPlayTapped() {
        delegate?.onPlayTapped()
    }

    @objc private func stopPlayingTapped() {
        delegate?.onStopTapped()
    }

    @objc private func onPauseResumeTapped() {
        delegate?.onPauseResumeTapped()
    }

    @objc private func previousTapped() {
        delegate?.onBackwardTapped()
    }

    @objc private func nextTapped() {
        delegate?.onForwardTapped()
    }

    @objc private func repeatTapped() {
        delegate?.onRepeatTapped()
    }

    @objc private func cancelDownloadTapped() {
        delegate?.onCancelDownloadTapped()
    }
}
