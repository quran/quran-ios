//
//  CircularDownloadProgressButton.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import Localization
import SwiftUI
import UIKit
import UIx

/// A download's progress as a ring with a stop square, like the App Store's, for bars that take UIKit views.
/// Tapping it cancels the download.
@available(iOS 17.0, *)
public final class CircularDownloadProgressButton: UIButton {
    // MARK: Lifecycle

    public init(cancel: UIAction) {
        super.init(frame: .zero)
        addAction(cancel, for: .primaryActionTriggered)

        progressView.isUserInteractionEnabled = false
        addAutoLayoutSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthConstraint,
            heightConstraint,
        ])
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: Self, _: UITraitCollection) in
            button.updateLength()
        }

        isAccessibilityElement = true
        accessibilityTraits = [.button, .updatesFrequently]
        accessibilityLabel = lAndroid("cancel")
        updateLength()
        updateProgress()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    /// The download's progress, from 0 to 1.
    public var progress: Double = 0 {
        didSet {
            if progress != oldValue {
                updateProgress()
            }
        }
    }

    override public var intrinsicContentSize: CGSize {
        // Room to tap around the ring.
        let side = scaled(26) + scaled(16)
        return CGSize(width: side, height: side)
    }

    // MARK: Private

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.locale = .fixedCurrentLocaleNumbers
        return formatter
    }()

    private lazy var progressView = makeConfiguration().makeContentView()
    private lazy var widthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
    private lazy var heightConstraint = progressView.heightAnchor.constraint(equalToConstant: 0)

    private func scaled(_ value: CGFloat) -> CGFloat {
        UIFontMetrics.default.scaledValue(for: value, compatibleWith: traitCollection)
    }

    private func updateLength() {
        widthConstraint.constant = scaled(26)
        heightConstraint.constant = scaled(26)
        invalidateIntrinsicContentSize()
    }

    private func makeConfiguration() -> UIHostingConfiguration<CircularDownloadingView, EmptyView> {
        let progress = progress
        return UIHostingConfiguration { CircularDownloadingView(progress: progress) }
            .margins(.all, 0)
    }

    private func updateProgress() {
        progressView.configuration = makeConfiguration()
        let percent = Self.percentFormatter.format(min(max(progress, 0), 1))
        accessibilityValue = [l("downloading_title"), percent].joined(separator: l("list.separator.comma"))
    }
}
