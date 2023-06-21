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
import Utilities
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
    }

    func setBarsHidden(_ hidden: Bool) {
        audioView?.alpha = hidden ? 0 : 1
        audioView?.isUserInteractionEnabled = !hidden
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

    private weak var bottomBarConstraint: NSLayoutConstraint?

    private let tapGesture = UITapGestureRecognizer()

    private var audioView: UIView?

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
