//
//  AudioBannerHostingTests.swift
//
//
//  Created by Claude Fable 5.1 on 2026-10-24.
//

import SwiftUI
import UIKit
import XCTest
@testable import AudioBannerFeature

/// The banner is pinned to the bottom of the reader without a height constraint, so its hosting
/// controller's safe area decides how tall it is. Counting the keyboard as bottom safe area lifted
/// the banner to the middle of the page (#1149, #1199).
@MainActor
final class AudioBannerHostingTests: XCTestCase {
    // MARK: Internal

    override func tearDown() {
        super.tearDown()
        window?.isHidden = true
        window = nil
    }

    func test_hostingControllerExcludesKeyboardFromSafeArea() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("UIHostingController.safeAreaRegions requires iOS 16.4.")
        }
        let banner = try XCTUnwrap(
            AudioBannerBuilder.makeHostingController(rootView: Color.red) as? UIHostingController<Color>
        )

        XCTAssertEqual(banner.safeAreaRegions, .container)
    }

    func test_bannerSitsAtReaderBottomAboveHomeIndicator() {
        let reader = makeReader(contentHeight: 60)
        spinRunLoop(for: 0.3)

        let frame = reader.banner.view.frame
        XCTAssertEqual(frame.maxY, reader.container.view.bounds.maxY)
        XCTAssertEqual(frame.height, 60 + reader.container.view.safeAreaInsets.bottom)
    }

    // MARK: Private

    private struct Reader {
        let container: UIViewController
        let banner: UIViewController
    }

    private var window: UIWindow?

    /// Hosts the banner like `QuranView` does: leading, trailing and bottom pinned, no height.
    private func makeReader(contentHeight: CGFloat) -> Reader {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        self.window = window
        let container = UIViewController()
        window.rootViewController = container
        window.makeKeyAndVisible()

        let banner = AudioBannerBuilder.makeHostingController(rootView: Color.red.frame(height: contentHeight))
        container.addChild(banner)
        banner.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(banner.view)
        NSLayoutConstraint.activate([
            banner.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            banner.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            banner.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])
        banner.didMove(toParent: container)
        return Reader(container: container, banner: banner)
    }

    private func spinRunLoop(for duration: TimeInterval) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: duration))
    }
}
