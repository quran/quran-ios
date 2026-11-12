//
//  QuranView.swift
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
import NoorUI
import UIKit
import UIx
import ViewConstrainer

@MainActor
protocol QuranViewDelegate: AnyObject {
    func onQuranViewTapped(_ quranView: QuranView)
    /// Whether the space bar can pause or resume the recitation, which is while it's playing or paused.
    func canTogglePlayPause(in quranView: QuranView) -> Bool
    func onQuranViewPlayPauseKeyPressed(_ quranView: QuranView)
}

class QuranView: UIView, UIGestureRecognizerDelegate, UINavigationBarDelegate {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    init() {
        super.init(frame: .zero)
        setUp()
    }

    // MARK: Internal

    weak var delegate: QuranViewDelegate?

    var contentView: UIView?

    let navigationBar = UINavigationBar()
    let navigationItem = UINavigationItem()

    /// Space pauses and resumes the recitation from a hardware keyboard, as on a Mac. It takes priority over the system,
    /// which would otherwise activate the focused verse, and is left alone while text in the reader is being edited.
    /// Editors presented over the reader aren't in its responder chain, so they keep space for typing.
    override var keyCommands: [UIKeyCommand]? {
        let commands = super.keyCommands ?? []
        guard canTogglePlayPause else {
            return commands.isEmpty ? nil : commands
        }
        return commands + [playPauseCommand]
    }

    override func layoutSubviews() {
        navigationItem.titleView?.setNeedsLayout()
        super.layoutSubviews()
        configureNavigationBarScrollEdgeEffectIfNeeded()
        configureAudioBarScrollEdgeEffectIfNeeded()
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        .topAttached
    }

    func addWordPointerView(_ wordPointerView: UIView) {
        addAutoLayoutSubview(wordPointerView)
        wordPointerView.vc.edges()
    }

    func addContentView(_ contentView: UIView) {
        self.contentView = contentView
        addAutoLayoutSubview(contentView)
        contentView.vc
            .verticalEdges()
            .horizontalEdges()
        sendSubviewToBack(contentView)
    }

    func addAudioBannerView(_ audioBannerView: UIView) {
        audioView = audioBannerView
        // Toasts, the banner's own included, stay above the audio bar while it shows.
        audioBannerView.keepsToastsAbove = true
        addAutoLayoutSubview(audioBannerView)
        audioBannerView.vc
            .horizontalEdges()
            .bottom()
        updateAudioBarVisibility()
    }

    func setBarsHidden(_ hidden: Bool, animated: Bool = false, completion: (() -> Void)? = nil) {
        let navigationBarStateChanged = navigationBarHidden != hidden
        let audioBarStateChanged = audioBarHidden != hidden
        navigationBarHidden = hidden
        audioBarHidden = hidden
        configureNavigationBarScrollEdgeEffectIfNeeded()
        configureAudioBarScrollEdgeEffectIfNeeded()

        barsVisibilityAnimationID &+= 1
        let animationID = barsVisibilityAnimationID
        let animateNavigationBar = prepareBarForVisibilityTransition(
            navigationBar,
            hidden: hidden,
            animated: animated,
            stateChanged: navigationBarStateChanged
        )
        let animateAudioBar = prepareBarForVisibilityTransition(
            audioView,
            hidden: hidden,
            animated: animated,
            stateChanged: audioBarStateChanged
        )
        guard animateNavigationBar || animateAudioBar else {
            completion?()
            return
        }

        NoorAnimation.animate {
            if animateNavigationBar {
                self.navigationBar.alpha = hidden ? 0 : 1
            }
            if animateAudioBar {
                self.audioView?.alpha = hidden ? 0 : 1
            }
        } completion: { [weak self] in
            guard let self, barsVisibilityAnimationID == animationID else { return }
            if animateNavigationBar, navigationBarHidden == hidden {
                updateNavigationBarVisibility()
            }
            if animateAudioBar, audioBarHidden == hidden {
                updateAudioBarVisibility()
            }
            completion?()
        }
    }

    func setAudioBarHidden(_ hidden: Bool) {
        audioBarHidden = hidden
        configureAudioBarScrollEdgeEffectIfNeeded()
        audioView?.layer.removeAllAnimations()
        updateAudioBarVisibility()
    }

    func refreshScrollEdgeInteractions() {
        configureNavigationBarScrollEdgeEffectIfNeeded()
        configureAudioBarScrollEdgeEffectIfNeeded()
    }

    @objc
    func onViewTapped(_ sender: UITapGestureRecognizer) {
        if let audioView, audioView.bounds.contains(sender.location(in: audioView)), audioView.isUserInteractionEnabled {
            return
        }
        delegate?.onQuranViewTapped(self)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer != tapGesture || !isFirstResponder // dismiss bars only if not first responder
    }

    // MARK: Private

    private let tapGesture = UITapGestureRecognizer()
    private var audioView: UIView?
    private var navigationBarHidden = false
    private var audioBarHidden = false
    // Prevent an interrupted animation from finalizing a newer visibility request.
    private var barsVisibilityAnimationID = 0
    private var navigationBarScrollEdgeInteraction: (any UIInteraction)?
    private var audioBarScrollEdgeInteraction: (any UIInteraction)?

    private lazy var playPauseCommand: UIKeyCommand = {
        let command = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(toggleRecitation))
        command.wantsPriorityOverSystemBehavior = true
        return command
    }()

    private var canTogglePlayPause: Bool {
        guard let delegate, delegate.canTogglePlayPause(in: self) else {
            return false
        }
        // Text being edited in the reader keeps space for typing.
        return !(findFirstResponder() is UITextInput)
    }

    /// Mirrors tapping the audio bar's play or pause button.
    @objc
    private func toggleRecitation() {
        guard canTogglePlayPause else {
            return
        }
        delegate?.onQuranViewPlayPauseKeyPressed(self)
    }

    private func configureNavigationBarScrollEdgeEffectIfNeeded() {
        guard #available(iOS 26.0, *) else { return }

        guard !navigationBarHidden,
              let scrollView = contentScrollView()
        else {
            if let interaction = navigationBarScrollEdgeInteraction {
                navigationBar.removeInteraction(interaction)
                navigationBarScrollEdgeInteraction = nil
            }
            return
        }

        let interaction: UIScrollEdgeElementContainerInteraction
        if let existingInteraction = navigationBarScrollEdgeInteraction as? UIScrollEdgeElementContainerInteraction {
            interaction = existingInteraction
        } else {
            interaction = UIScrollEdgeElementContainerInteraction()
            interaction.edge = .top
            navigationBarScrollEdgeInteraction = interaction
            navigationBar.addInteraction(interaction)
        }
        interaction.scrollView = scrollView
    }

    private func configureAudioBarScrollEdgeEffectIfNeeded() {
        guard #available(iOS 26.0, *) else { return }
        guard let audioView else { return }

        guard !audioBarHidden,
              let scrollView = contentScrollView()
        else {
            if let interaction = audioBarScrollEdgeInteraction {
                audioView.removeInteraction(interaction)
                audioBarScrollEdgeInteraction = nil
            }
            return
        }

        let interaction: UIScrollEdgeElementContainerInteraction
        if let existingInteraction = audioBarScrollEdgeInteraction as? UIScrollEdgeElementContainerInteraction {
            interaction = existingInteraction
        } else {
            interaction = UIScrollEdgeElementContainerInteraction()
            interaction.edge = .bottom
            audioBarScrollEdgeInteraction = interaction
            audioView.addInteraction(interaction)
        }
        interaction.scrollView = scrollView
    }

    private func contentScrollView() -> UIScrollView? {
        guard let contentViewController = contentView?.nearestViewController,
              let pageViewController = contentViewController.findViewController(ofType: UIPageViewController.self),
              let pageView = pageViewController.mostVisibleViewController?.viewIfLoaded
        else {
            return nil
        }

        return pageView.mostVisibleSubview(ofType: UIScrollView.self)
    }

    private func updateNavigationBarVisibility() {
        updateBarVisibility(navigationBar, hidden: navigationBarHidden)
    }

    private func updateAudioBarVisibility() {
        updateBarVisibility(audioView, hidden: audioBarHidden)
    }

    private func prepareBarForVisibilityTransition(
        _ view: UIView?,
        hidden: Bool,
        animated: Bool,
        stateChanged: Bool
    ) -> Bool {
        guard let view else { return false }
        guard animated, stateChanged else {
            view.layer.removeAllAnimations()
            updateBarVisibility(view, hidden: hidden)
            return false
        }

        if !hidden, view.isHidden {
            view.alpha = 0
        }
        view.isHidden = false
        view.isUserInteractionEnabled = !hidden
        return true
    }

    private func updateBarVisibility(_ view: UIView?, hidden: Bool) {
        view?.isHidden = hidden
        view?.isUserInteractionEnabled = !hidden
        view?.alpha = 1
    }

    private func setUp() {
        clipsToBounds = true
        tapGesture.addTarget(self, action: #selector(onViewTapped(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        // navigation bar
        addAutoLayoutSubview(navigationBar)
        navigationBar.vc.horizontalEdges()
        safeAreaLayoutGuide.topAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
        navigationBar.pushItem(navigationItem, animated: false)
        navigationBar.delegate = self
    }
}
