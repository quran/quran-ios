//
//  DownloadButton.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/14/17.
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

import DownloadButton
import Localization
import UIKit
import UIx

public final class DownloadButton: UIView {
    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    // MARK: Public

    public var onButtonTapped: ((DownloadButton) -> Void)?

    public var state: DownloadState = .notDownloaded {
        didSet {
            stateViews.forEach { $0.isHidden = true }
            stateConstraints.forEach { $0.isActive = false }
            switch state {
            case .notDownloaded:
                downloadConstraints.forEach { $0.isActive = true }
                download.isHidden = false
            case .pendingDownloading, .pendingUpgrading:
                pendingConstraints.forEach { $0.isActive = true }
                pending.isHidden = false
                pending.stopSpin()
                pending.startSpin()
            case .downloading(progress: let progress), .downloadingUpgrade(progress: let progress):
                downloadingConstraints.forEach { $0.isActive = true }
                downloading.isHidden = false
                downloading.progress = CGFloat(progress)
            case .downloaded:
                downloadedConstraints.forEach { $0.isActive = true }
            // all will be hidden
            case .needsUpgrade:
                upgradeConstraints.forEach { $0.isActive = true }
                upgrade.isHidden = false
            }
        }
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self {
            return super.hitTest(CGPoint(x: bounds.maxX - 10, y: bounds.midY), with: event)
        }
        return result
    }

    // MARK: Internal

    var downloadConstraints: [NSLayoutConstraint] = []
    var pendingConstraints: [NSLayoutConstraint] = []
    var downloadingConstraints: [NSLayoutConstraint] = []
    var downloadedConstraints: [NSLayoutConstraint] = []
    var upgradeConstraints: [NSLayoutConstraint] = []

    let download: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(NoorImage.download.uiImage.tintedImage(withColor: .appIdentity), for: .normal)
        return button
    }()

    let pending: PKPendingView = {
        let button = PKPendingView()
        button.tintColor = .appIdentity
        return button
    }()

    let downloading: PKStopDownloadButton = {
        let button = PKStopDownloadButton()
        button.tintColor = .appIdentity
        button.filledLineStyleOuter = false
        return button
    }()

    let upgrade: UIButton = {
        let button = UIButton(type: .custom)

        let backgroundImage = UIImage.borderedImage(
            withFill: .clear,
            radius: 4.0,
            lineColor: .appIdentity,
            lineWidth: 1.0
        )
        let highlightedBackgroundImage = UIImage.filledImage(
            fillColor: .appIdentity,
            radius: 4.0,
            lineColor: .appIdentity,
            lineWidth: 1.0
        )
        button.setBackgroundImage(backgroundImage, for: .normal)
        button.setBackgroundImage(highlightedBackgroundImage, for: .highlighted)

        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle(l("upgradeTranslationButtonTitle"), for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.setTitleColor(.appIdentity, for: .normal)

        return button
    }()

    // MARK: Private

    private var stateViews: [UIView] {
        [download, pending, downloading, upgrade]
    }

    private var stateConstraints: [NSLayoutConstraint] {
        [downloadConstraints, pendingConstraints, downloadingConstraints, downloadedConstraints, upgradeConstraints].flatMap { $0 }
    }

    private func setUp() {
        for view in stateViews {
            addAutoLayoutSubview(view)
            var constraints = view.vc.trailing()
                .centerY()
                .chain

            if view == upgrade {
                constraints.append(view.vc.leading(to: self).constraint)
            } else {
                constraints.append(vc.width(by: 45).constraint)
            }

            if view == download {
                downloadConstraints = constraints
            } else if view == pending {
                pendingConstraints = constraints
            } else if view == downloading {
                downloadingConstraints = constraints
            } else if view == upgrade {
                upgradeConstraints = constraints
            }
        }

        downloadedConstraints = [widthAnchor.constraint(equalToConstant: 0)]

        for control in [download, pending, downloading.stopButton, upgrade] {
            control?.addTarget(self, action: #selector(onAnyButtonTapped), for: .touchUpInside)
        }

        state = .needsUpgrade
    }

    @objc
    private func onAnyButtonTapped() {
        onButtonTapped?(self)
    }
}
