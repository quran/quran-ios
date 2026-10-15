import Localization
import SwiftUI
import UIx
import XCTest
@testable import NoorUI

/// The package test host never finishes UIKit presentation transitions (their completions don't run),
/// so the window's root is a presenter fake that presents and dismisses synchronously.
@MainActor
final class TextFieldAlertTests: XCTestCase {
    func test_presentsAlertWithTitleTextAndPlaceholder() throws {
        let model = NameModel(name: "Study")
        let (_, presenter) = makeWindow(model: model)

        model.isPresented = true
        let alert = try waitForAlert(in: presenter)

        XCTAssertEqual(alert.title, "Rename")
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.textFields?.first?.text, "Study")
        XCTAssertEqual(alert.textFields?.first?.placeholder, "Name")
        XCTAssertEqual(alert.actions.map(\.title), [lAndroid("cancel"), "Rename"])
    }

    func test_rejectedText_presentsAlertAgainWithTypedTextAndMessage() throws {
        let model = NameModel(name: "Study")
        let (window, presenter) = makeWindow(model: model)
        model.isPresented = true
        let firstAlert = try waitForAlert(in: presenter)

        try tap(confirming: true, on: firstAlert, typing: "Favorites", in: window, presenter: presenter)

        let secondAlert = try waitForAlert(in: presenter) { $0 !== firstAlert }
        XCTAssertEqual(model.confirmedNames, ["Favorites"])
        XCTAssertEqual(secondAlert.message, "Favorites is reserved")
        XCTAssertEqual(secondAlert.textFields?.first?.text, "Favorites")
        XCTAssertTrue(model.isPresented)
    }

    func test_sameImmediateRejectionTwice_presentsAlertAgain() throws {
        // A reserved name is rejected before any database work, so `confirm` doesn't suspend.
        let model = NameModel(name: "Study", suspendsBeforeResult: false)
        let (window, presenter) = makeWindow(model: model)
        model.isPresented = true
        let firstAlert = try waitForAlert(in: presenter)
        try tap(confirming: true, on: firstAlert, typing: "Favorites", in: window, presenter: presenter)
        let secondAlert = try waitForAlert(in: presenter) { $0 !== firstAlert }

        // The message and text don't change this time.
        try tap(confirming: true, on: secondAlert, typing: "Favorites", in: window, presenter: presenter)

        let thirdAlert = try waitForAlert(in: presenter) { $0 !== secondAlert }
        XCTAssertEqual(model.confirmedNames, ["Favorites", "Favorites"])
        XCTAssertEqual(thirdAlert.message, "Favorites is reserved")
        XCTAssertEqual(thirdAlert.textFields?.first?.text, "Favorites")
    }

    func test_returnKey_confirmsOnceWithTypedText() throws {
        let model = NameModel(name: "Study")
        let (_, presenter) = makeWindow(model: model)
        model.isPresented = true
        let firstAlert = try waitForAlert(in: presenter)
        let textField = try XCTUnwrap(firstAlert.textFields?.first)
        textField.text = "Favorites"

        textField.sendActions(for: .primaryActionTriggered)
        textField.sendActions(for: .primaryActionTriggered)

        let secondAlert = try waitForAlert(in: presenter) { $0 !== firstAlert }
        XCTAssertEqual(model.confirmedNames, ["Favorites"])
        XCTAssertEqual(secondAlert.message, "Favorites is reserved")
        XCTAssertEqual(secondAlert.textFields?.first?.text, "Favorites")
    }

    func test_requestBeforeDismissalRenders_presentsAlertAgain() throws {
        let model = NameModel(name: "Favorites")
        model.message = "Favorites is reserved"
        let (window, presenter) = makeWindow(model: model)
        model.isPresented = true
        let firstAlert = try waitForAlert(in: presenter)
        let controller = try XCTUnwrap(window.rootViewController?.findViewController(ofType: TextFieldAlertViewController.self))

        presenter.dismiss(animated: true)
        controller.handle(confirming: false, enteredText: "Favorites")
        // Asked again with the same message before SwiftUI renders `isPresented == false`.
        model.isPresented = true

        let secondAlert = try waitForAlert(in: presenter) { $0 !== firstAlert }
        XCTAssertEqual(secondAlert.message, "Favorites is reserved")
        XCTAssertEqual(secondAlert.textFields?.first?.text, "Favorites")
    }

    func test_acceptedText_staysDismissed() throws {
        let model = NameModel(name: "Study")
        let (window, presenter) = makeWindow(model: model)
        model.isPresented = true
        let alert = try waitForAlert(in: presenter)

        try tap(confirming: true, on: alert, typing: "Duas", in: window, presenter: presenter)
        waitUntil(in: window) { model.confirmedNames == ["Duas"] && !model.isConfirming }

        XCTAssertFalse(model.isPresented)
        XCTAssertNil(presenter.presentedViewController)
    }

    func test_cancel_dismissesWithoutConfirming() throws {
        let model = NameModel(name: "Study")
        let (window, presenter) = makeWindow(model: model)
        model.isPresented = true
        let alert = try waitForAlert(in: presenter)

        try tap(confirming: false, on: alert, typing: "Favorites", in: window, presenter: presenter)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        window.layoutIfNeeded()

        XCTAssertFalse(model.isPresented)
        XCTAssertEqual(model.confirmedNames, [])
        XCTAssertNil(presenter.presentedViewController)
    }

    // MARK: Private

    private func makeWindow(model: NameModel) -> (UIWindow, PresenterFake) {
        let presenter = PresenterFake()
        let hostingController = UIHostingController(rootView: NameAlertView(model: model))
        presenter.addChild(hostingController)
        presenter.view.addSubview(hostingController.view)
        hostingController.view.frame = presenter.view.bounds
        hostingController.didMove(toParent: presenter)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        addTeardownBlock { window.isHidden = true }
        return (window, presenter)
    }

    private func waitForAlert(
        in presenter: PresenterFake,
        matching predicate: @escaping (UIAlertController) -> Bool = { _ in true }
    ) throws -> UIAlertController {
        waitUntil(in: presenter.view.window) {
            (presenter.presentedViewController as? UIAlertController).map(predicate) ?? false
        }
        return try XCTUnwrap(presenter.presentedViewController as? UIAlertController)
    }

    /// Mirrors UIKit, which calls a button's handler after the alert has finished dismissing.
    private func tap(
        confirming: Bool,
        on alert: UIAlertController,
        typing text: String,
        in window: UIWindow,
        presenter: PresenterFake
    ) throws {
        let controller = try XCTUnwrap(window.rootViewController?.findViewController(ofType: TextFieldAlertViewController.self))
        alert.textFields?.first?.text = text
        presenter.dismiss(animated: true)
        controller.handle(confirming: confirming, enteredText: alert.textFields?.first?.text)
    }

    private func waitUntil(in window: UIWindow?, _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(2)
        while !condition(), Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
            window?.layoutIfNeeded()
        }
        XCTAssertTrue(condition(), "Timed out")
    }
}

@MainActor
private final class NameModel: ObservableObject {
    init(name: String, suspendsBeforeResult: Bool = true) {
        self.name = name
        self.suspendsBeforeResult = suspendsBeforeResult
    }

    @Published var isPresented = false
    @Published var name: String
    @Published var message: String?
    private(set) var confirmedNames: [String] = []
    private(set) var isConfirming = false

    func confirm() async {
        isConfirming = true
        defer { isConfirming = false }
        confirmedNames.append(name)
        if suspendsBeforeResult {
            // Suspend like a database write before reporting the result.
            await Task.yield()
        }
        if name == "Favorites" {
            message = "\(name) is reserved"
            isPresented = true
        } else {
            message = nil
        }
    }

    private let suspendsBeforeResult: Bool
}

private struct NameAlertView: View {
    @ObservedObject var model: NameModel

    var body: some View {
        Color.clear
            .textFieldAlert(
                "Rename",
                isPresented: $model.isPresented,
                text: $model.name,
                placeholder: "Name",
                message: model.message,
                confirmTitle: "Rename",
                confirm: { await model.confirm() }
            )
    }
}

private final class PresenterFake: UIViewController {
    override var presentedViewController: UIViewController? {
        presented
    }

    override func present(_ viewController: UIViewController, animated _: Bool, completion: (() -> Void)? = nil) {
        presented = viewController
        completion?()
    }

    override func dismiss(animated _: Bool, completion: (() -> Void)? = nil) {
        presented = nil
        completion?()
    }

    private var presented: UIViewController?
}
