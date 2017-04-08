//
//  TranslationDownloadButton.swift
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

import UIKit
import DownloadButton

class TranslationDownloadButton: UIView {

    var state: Translation.State = .notDownloaded {
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

    var onButtonTapped: ((TranslationDownloadButton) -> Void)?

    var downloadConstraints: [NSLayoutConstraint] = []
    var pendingConstraints: [NSLayoutConstraint] = []
    var downloadingConstraints: [NSLayoutConstraint] = []
    var downloadedConstraints: [NSLayoutConstraint] = []
    var upgradeConstraints: [NSLayoutConstraint] = []

    let download: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "download-30").tintedImage(withColor: .appIdentity()), for: .normal)
        return button
    }()

    let pending: PKPendingView = {
        let button = PKPendingView()
        button.tintColor = .appIdentity()
        return button
    }()

    let downloading: PKStopDownloadButton = {
        let button = PKStopDownloadButton()
        button.tintColor = .appIdentity()
        button.filledLineStyleOuter = false
        return button
    }()

    let upgrade: UIButton = {
        let button = UIButton(type: .custom)

        let backgroundImage = UIImage.buttonBackground(with: .appIdentity())
            .resizableImage(withCapInsets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
        button.setBackgroundImage(backgroundImage, for: .normal)
        button.setBackgroundImage(UIImage.highlitedButtonBackground(with: .appIdentity()), for: .highlighted)

        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle(NSLocalizedString("upgradeTranslationButtonTitle", comment: ""), for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.setTitleColor(.appIdentity(), for: .normal)

        return button
    }()

    private var stateViews: [UIView] {
        return [download, pending, downloading, upgrade]
    }
    private var stateConstraints: [NSLayoutConstraint] {
        return [downloadConstraints, pendingConstraints, downloadingConstraints, downloadedConstraints, upgradeConstraints].flatMap { $0 }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        for view in stateViews {
            addAutoLayoutSubview(view)
            var constraints: [NSLayoutConstraint] = []
            constraints.append(addParentTrailingConstraint(view))
            constraints.append(addParentCenterYConstraint(view))

            if view == upgrade {
                constraints.append(view.leadingAnchor.constraint(equalTo: leadingAnchor))
            } else {
                constraints.append(widthAnchor.constraint(equalToConstant: 45))
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
            control.addTarget(self, action: #selector(onAnyButtonTapped), for: .touchUpInside)
        }

        state = .needsUpgrade
    }

    @objc private func onAnyButtonTapped() {
        onButtonTapped?(self)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self {
            return super.hitTest(CGPoint(x: bounds.maxX - 10, y: bounds.midY), with: event)
        }
        return result
    }
}
