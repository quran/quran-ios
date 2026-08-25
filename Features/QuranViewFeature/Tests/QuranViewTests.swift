import UIKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranViewTests: XCTestCase {
    func test_hidingBarsRemovesAudioBarScrollEdgeInteraction() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        let interaction = try audioBarInteraction(in: context.audioView)

        context.sut.setBarsHidden(true)

        XCTAssertFalse(context.audioView.interactions.contains { $0 === interaction })
    }

    func test_layoutWhileBarsAreHiddenDoesNotRecreateAudioBarScrollEdgeInteraction() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        context.sut.setBarsHidden(true)

        context.sut.layoutSubviews()

        XCTAssertTrue(
            context.audioView.interactions.compactMap { $0 as? UIScrollEdgeElementContainerInteraction }.isEmpty
        )
    }

    func test_showingBarsReconnectsAudioBarScrollEdgeInteractionToVerticalContentScrollView() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        context.sut.setBarsHidden(true)

        context.sut.setBarsHidden(false)

        let interaction = try audioBarInteraction(in: context.audioView)
        XCTAssertIdentical(interaction.scrollView, context.contentScrollView)
    }

    func test_hidingBarsRemovesNavigationBarScrollEdgeInteraction() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        let interaction = try scrollEdgeInteraction(in: context.sut.navigationBar)

        context.sut.setBarsHidden(true)

        XCTAssertFalse(context.sut.navigationBar.interactions.contains { $0 === interaction })
    }

    func test_layoutWhileBarsAreHiddenDoesNotRecreateNavigationBarScrollEdgeInteraction() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        context.sut.setBarsHidden(true)

        context.sut.layoutSubviews()

        XCTAssertTrue(
            context.sut.navigationBar.interactions.compactMap { $0 as? UIScrollEdgeElementContainerInteraction }.isEmpty
        )
    }

    func test_showingBarsReconnectsNavigationBarScrollEdgeInteractionToVerticalContentScrollView() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        context.sut.setBarsHidden(true)

        context.sut.setBarsHidden(false)

        let interaction = try scrollEdgeInteraction(in: context.sut.navigationBar)
        XCTAssertIdentical(interaction.scrollView, context.contentScrollView)
    }

    func test_hidingBarsImmediatelyHidesBarsWithoutChangingTheirAlpha() {
        let context = makeSut()

        context.sut.setBarsHidden(true)

        XCTAssertTrue(context.audioView.isHidden)
        XCTAssertTrue(context.sut.navigationBar.isHidden)
        XCTAssertEqual(context.audioView.alpha, 1)
        XCTAssertEqual(context.sut.navigationBar.alpha, 1)
    }

    func test_showingBarsUnhidesBars() {
        let context = makeSut()
        context.sut.setBarsHidden(true)

        context.sut.setBarsHidden(false)

        XCTAssertFalse(context.audioView.isHidden)
        XCTAssertFalse(context.sut.navigationBar.isHidden)
    }

    func test_animatedHidingEndsWithHiddenBarsAtFullAlpha() {
        let context = makeSut()
        let animationCompleted = expectation(description: "Animation completed")

        context.sut.setBarsHidden(true, animated: true) {
            animationCompleted.fulfill()
        }
        wait(for: [animationCompleted], timeout: 1)

        XCTAssertTrue(context.audioView.isHidden)
        XCTAssertTrue(context.sut.navigationBar.isHidden)
        XCTAssertEqual(context.audioView.alpha, 1)
        XCTAssertEqual(context.sut.navigationBar.alpha, 1)
    }

    func test_animatedShowingEndsWithVisibleBarsAtFullAlpha() {
        let context = makeSut()
        context.sut.setBarsHidden(true)
        let animationCompleted = expectation(description: "Animation completed")

        context.sut.setBarsHidden(false, animated: true) {
            animationCompleted.fulfill()
        }
        wait(for: [animationCompleted], timeout: 1)

        XCTAssertFalse(context.audioView.isHidden)
        XCTAssertFalse(context.sut.navigationBar.isHidden)
        XCTAssertEqual(context.audioView.alpha, 1)
        XCTAssertEqual(context.sut.navigationBar.alpha, 1)
    }

    func test_showingOnlyAudioBarKeepsNavigationBarHiddenWithoutScrollEdgeInteraction() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIScrollEdgeElementContainerInteraction requires iOS 26.")
        }
        let context = makeSut()
        context.sut.setBarsHidden(true)

        context.sut.setAudioBarHidden(false)

        XCTAssertFalse(context.audioView.isHidden)
        XCTAssertTrue(context.sut.navigationBar.isHidden)
        XCTAssertTrue(
            context.sut.navigationBar.interactions.compactMap { $0 as? UIScrollEdgeElementContainerInteraction }.isEmpty
        )
    }

    func test_addingAudioBarWhileBarsAreHiddenKeepsItHidden() {
        let sut = QuranView()
        sut.setBarsHidden(true)
        let audioView = UIView()

        sut.addAudioBannerView(audioView)

        XCTAssertTrue(audioView.isHidden)
        XCTAssertFalse(audioView.isUserInteractionEnabled)
    }

    private struct TestContext {
        let retainedHostViewController: UIViewController
        let sut: QuranView
        let contentScrollView: UIScrollView
        let audioView: UIView
    }

    private func makeSut() -> TestContext {
        let sut = QuranView()
        sut.frame = CGRect(x: 0, y: 0, width: 390, height: 844)

        let hostViewController = UIViewController()
        hostViewController.view = sut

        let contentViewController = UIViewController()
        hostViewController.addChild(contentViewController)
        sut.addContentView(contentViewController.view)
        contentViewController.didMove(toParent: hostViewController)

        let pageContentViewController = UIViewController()
        let contentScrollView = UIScrollView(frame: sut.bounds)
        contentScrollView.contentSize = CGSize(width: sut.bounds.width, height: sut.bounds.height * 2)
        pageContentViewController.view.addSubview(contentScrollView)

        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.setViewControllers(
            [pageContentViewController],
            direction: .forward,
            animated: false
        )
        contentViewController.addChild(pageViewController)
        contentViewController.view.addSubview(pageViewController.view)
        pageViewController.view.frame = sut.bounds
        pageViewController.didMove(toParent: contentViewController)

        let audioView = UIView()
        sut.addAudioBannerView(audioView)
        sut.layoutSubviews()
        return TestContext(
            retainedHostViewController: hostViewController,
            sut: sut,
            contentScrollView: contentScrollView,
            audioView: audioView
        )
    }

    @available(iOS 26.0, *)
    private func audioBarInteraction(in audioView: UIView) throws -> UIScrollEdgeElementContainerInteraction {
        try scrollEdgeInteraction(in: audioView)
    }

    @available(iOS 26.0, *)
    private func scrollEdgeInteraction(in view: UIView) throws -> UIScrollEdgeElementContainerInteraction {
        try XCTUnwrap(view.interactions.compactMap { $0 as? UIScrollEdgeElementContainerInteraction }.first)
    }
}
