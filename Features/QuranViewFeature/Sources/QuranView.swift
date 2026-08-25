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
import UIKit
import UIx
import ViewConstrainer

@MainActor
protocol QuranViewDelegate: AnyObject {
    func onQuranViewTapped(_ quranView: QuranView)
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

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .beginFromCurrentState
        ) {
            if animateNavigationBar {
                self.navigationBar.alpha = hidden ? 0 : 1
            }
            if animateAudioBar {
                self.audioView?.alpha = hidden ? 0 : 1
            }
        } completion: { [weak self] _ in
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
