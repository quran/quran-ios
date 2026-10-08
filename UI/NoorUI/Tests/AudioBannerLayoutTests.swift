import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class AudioBannerLayoutTests: XCTestCase {
    // MARK: Banner

    func test_readyToPlayWithNonDefaultOptions_settles() {
        guard #available(iOS 17.0, *) else { return }
        for size in contentSizes {
            assertSettles(.readyToPlay(reciter: "Husary"), at: size)
        }
    }

    func test_playingWithNonDefaultOptions_settles() {
        guard #available(iOS 17.0, *) else { return }
        for size in contentSizes {
            assertSettles(.playing(paused: false, rate: 1.25), at: size)
        }
    }

    func test_textSizeChangeWhileShown_settles() {
        guard #available(iOS 17.0, *) else { return }
        for state: AudioBannerState in [.readyToPlay(reciter: "Husary"), .playing(paused: false, rate: 1.25)] {
            assertSettles(state, at: .large, changingTo: .accessibilityExtraExtraExtraLarge)
        }
    }

    // MARK: Options Button

    func test_optionsButtonSize_doesNotDependOnItsLayoutHistory() {
        guard #available(iOS 16.4, *) else { return }
        let button = UIHostingController(
            rootView: AudioOptionsButton(summary: options, action: {})
                .environment(\.dynamicTypeSize, .large)
        )
        button.safeAreaRegions = []
        let proposal = CGSize(width: 402, height: 874)
        let sizeBeforeShowing = button.sizeThatFits(in: proposal)

        let window = UIWindow(frame: CGRect(origin: .zero, size: proposal))
        window.rootViewController = button
        window.makeKeyAndVisible()
        spinRunLoop(for: 0.3)
        window.isHidden = true

        XCTAssertEqual(button.sizeThatFits(in: proposal), sizeBeforeShowing)
    }

    func test_optionsSummary_doesNotWidenTheOptionsButton() {
        for size in [DynamicTypeSize.large, .accessibility5] {
            let withSummary = fittingSize(AudioOptionsButton(summary: options, action: {}), size)
            let withoutSummary = fittingSize(AudioOptionsButton(summary: AudioOptionsSummary(), action: {}), size)

            XCTAssertEqual(withSummary.width, withoutSummary.width, "at \(size)")
        }
    }

    // MARK: Private

    private let contentSizes: [UIContentSizeCategory] = [.large, .extraExtraExtraLarge, .accessibilityExtraExtraLarge]
    private let options = AudioOptionsSummary(rate: 1.25, verseRuns: .finite(3))

    private func fittingSize(_ view: some View, _ dynamicTypeSize: DynamicTypeSize) -> CGSize {
        UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
            .sizeThatFits(in: CGSize(width: 402, height: 874))
    }

    @available(iOS 17.0, *)
    private func assertSettles(
        _ state: AudioBannerState,
        at size: UIContentSizeCategory,
        changingTo newSize: UIContentSizeCategory? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let message = "\(state) at \(size.rawValue)" + (newSize.map { " then \($0.rawValue)" } ?? "")
        let watchdog = HangWatchdog(message)
        let actions = AudioBannerActions(
            play: {}, pause: {}, resume: {}, stop: {}, backward: {}, forward: {},
            cancelDownloading: {}, reciters: {}, more: {}, setPlaybackRate: { _ in }
        )
        let hosted = HostedBanner(AudioBannerViewUI(state: state, actions: actions, options: options), contentSize: size)
        if let newSize {
            spinRunLoop(for: 0.3)
            hosted.setContentSize(newSize)
        }
        spinRunLoop(for: 0.4)
        let passes = hosted.monitor.passes
        spinRunLoop(for: 0.2)
        let idlePasses = hosted.monitor.passes - passes
        hosted.close()
        watchdog.finish()

        XCTAssertFalse(hosted.monitor.isOverBudget, "\(message) never settled", file: file, line: line)
        XCTAssertLessThanOrEqual(idlePasses, 2, "\(message) keeps laying out", file: file, line: line)
        XCTAssertGreaterThan(passes, 0, message, file: file, line: line)
    }

    private func spinRunLoop(for duration: TimeInterval) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: duration))
    }
}

/// Hosts the banner like the reader does: pinned to the bottom of a container with no height constraint.
@available(iOS 17.0, *)
@MainActor
private final class HostedBanner {
    // MARK: Lifecycle

    init(_ banner: AudioBannerViewUI, contentSize: UIContentSizeCategory) {
        hosting = UIHostingController(rootView: LayoutLoopGuard(monitor: monitor, content: banner))
        hosting.view.backgroundColor = nil
        window.rootViewController = container
        setContentSize(contentSize)
        window.makeKeyAndVisible()

        container.addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])
        hosting.didMove(toParent: container)
    }

    // MARK: Internal

    let monitor = LayoutPassMonitor()

    func setContentSize(_ category: UIContentSizeCategory) {
        container.traitOverrides.preferredContentSizeCategory = category
    }

    func close() {
        window.isHidden = true
    }

    // MARK: Private

    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
    private let container = UIViewController()
    private let hosting: UIHostingController<LayoutLoopGuard<AudioBannerViewUI>>
}

/// Counts the banner's layout passes. A layout loop spins inside a single UIKit layout pass,
/// so past the budget the guard stops rendering the banner to fail the test instead of hanging it.
private final class LayoutPassMonitor: ObservableObject {
    let budget = 100
    private(set) var passes = 0
    @Published private(set) var isOverBudget = false

    func recordPass() {
        passes += 1
        if passes > budget, !isOverBudget {
            isOverBudget = true
        }
    }
}

@available(iOS 16.0, *)
private struct LayoutLoopGuard<Content: View>: View {
    @ObservedObject var monitor: LayoutPassMonitor
    let content: Content

    var body: some View {
        if !monitor.isOverBudget {
            LayoutPassCounter(monitor: monitor) { content }
        }
    }
}

@available(iOS 16.0, *)
private struct LayoutPassCounter: Layout {
    let monitor: LayoutPassMonitor

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(proposal) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        monitor.recordPass()
        subviews.first?.place(at: bounds.origin, proposal: proposal)
    }
}

/// The playing layout places its controls inside a GeometryReader, so a loop there never resizes
/// the banner or reaches the guard. Crash with the reason rather than hang the test run.
private final class HangWatchdog: @unchecked Sendable {
    // MARK: Lifecycle

    init(_ message: String, timeout: TimeInterval = 10) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [self] in
            lock.lock()
            defer { lock.unlock() }
            if !isFinished {
                fatalError("\(message) is stuck in a layout loop")
            }
        }
    }

    // MARK: Internal

    func finish() {
        lock.lock()
        defer { lock.unlock() }
        isFinished = true
    }

    // MARK: Private

    private let lock = NSLock()
    private var isFinished = false
}
