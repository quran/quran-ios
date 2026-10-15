//
//  TextFieldAlert.swift
//
//
//  Created by Mohamed Afifi on 2026-10-15.
//

import Localization
import SwiftUI
import UIKit
import UIx

extension View {
    /// Presents an alert with one text field, a Cancel button, and a confirm button.
    ///
    /// Tapping either button sets `isPresented` to `false` before `confirm` runs. Set it back to `true`
    /// from `confirm` to ask again, for example with a `message` explaining why the text was rejected;
    /// the alert reappears right away with the typed text.
    ///
    /// SwiftUI's `alert(_:isPresented:)` can't do this reliably: it reports no end of its dismissal, so a
    /// `true` set while an async `confirm` runs may be dropped or shown only on an unrelated later view
    /// update. This alert is a `UIAlertController` presented from UIKit instead, which calls its button
    /// handlers only after the dismissal ends.
    public func textFieldAlert(
        _ title: String,
        isPresented: Binding<Bool>,
        text: Binding<String>,
        placeholder: String,
        message: String? = nil,
        confirmTitle: String,
        confirm: @escaping AsyncAction
    ) -> some View {
        modifier(TextFieldAlertModifier(
            configuration: TextFieldAlertConfiguration(
                title: title,
                message: message,
                placeholder: placeholder,
                cancelTitle: lAndroid("cancel"),
                confirmTitle: confirmTitle
            ),
            isPresentedValue: isPresented.wrappedValue,
            isPresented: isPresented,
            text: text,
            confirm: confirm
        ))
    }
}

struct TextFieldAlertConfiguration: Equatable {
    var title: String
    var message: String?
    var placeholder: String
    var cancelTitle: String
    var confirmTitle: String
}

/// Re-presenting relies on SwiftUI updating the presenter on every body pass of the view that applies
/// the modifier: `isPresentedValue` and the configuration change when the request or message does, and
/// the binding and closure fields are new values every pass, which makes SwiftUI update even when
/// `confirm` asks again with the same message. Keep them stored here (not captured once, say, in
/// `@State`), or the alert can miss a request to reappear.
@MainActor
private struct TextFieldAlertModifier: ViewModifier {
    let configuration: TextFieldAlertConfiguration
    let isPresentedValue: Bool
    let isPresented: Binding<Bool>
    let text: Binding<String>
    let confirm: AsyncAction

    func body(content: Content) -> some View {
        content.background(
            TextFieldAlertPresenter(
                state: TextFieldAlertPresenter.State(
                    configuration: configuration,
                    isPresented: isPresentedValue
                ),
                isPresented: isPresented,
                text: text,
                confirm: confirm
            )
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        )
    }
}

@MainActor
private struct TextFieldAlertPresenter: UIViewControllerRepresentable {
    struct State: Equatable {
        var configuration: TextFieldAlertConfiguration
        var isPresented: Bool
    }

    let state: State
    let isPresented: Binding<Bool>
    let text: Binding<String>
    let confirm: AsyncAction

    static func dismantleUIViewController(_ uiViewController: TextFieldAlertViewController, coordinator: ()) {
        uiViewController.dismissAlert()
    }

    func makeUIViewController(context: Context) -> TextFieldAlertViewController {
        TextFieldAlertViewController()
    }

    func updateUIViewController(_ uiViewController: TextFieldAlertViewController, context: Context) {
        uiViewController.update(
            configuration: state.configuration,
            isPresented: isPresented,
            text: text,
            confirm: confirm
        )
    }
}

/// Keeps a `UIAlertController` on screen while `isPresented` is `true`.
@MainActor
final class TextFieldAlertViewController: UIViewController {
    // MARK: Internal

    func update(
        configuration: TextFieldAlertConfiguration,
        isPresented: Binding<Bool>,
        text: Binding<String>,
        confirm: @escaping AsyncAction
    ) {
        self.configuration = configuration
        self.isPresented = isPresented
        self.text = text
        self.confirm = confirm
        if let alert {
            if alert.title != configuration.title {
                alert.title = configuration.title
            }
            if alert.message != configuration.message {
                alert.message = configuration.message
            }
        }
        presentOrDismissAlert()
    }

    /// UIKit calls `UIAlertAction` handlers once the alert has finished dismissing.
    func handle(confirming: Bool, enteredText: String?) {
        alert = nil
        alertPresenter = nil
        hasRetriedPresentation = false
        if let enteredText {
            text?.wrappedValue = enteredText
        }
        isPresented?.wrappedValue = false
        guard confirming, let confirm else {
            return
        }
        Task {
            await confirm()
        }
    }

    func dismissAlert() {
        hasRetriedPresentation = false
        guard let alert else {
            return
        }
        self.alert = nil
        if let alertPresenter, alertPresenter.presentedViewController === alert {
            alertPresenter.dismiss(animated: true)
        }
        alertPresenter = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentOrDismissAlert()
    }

    // MARK: Private

    private weak var alert: UIAlertController?
    private weak var alertPresenter: UIViewController?
    private var hasRetriedPresentation = false
    private var configuration: TextFieldAlertConfiguration?
    private var isPresented: Binding<Bool>?
    private var text: Binding<String>?
    private var confirm: AsyncAction?

    private func presentOrDismissAlert() {
        if isPresented?.wrappedValue == true {
            presentAlertIfNeeded()
        } else {
            dismissAlert()
        }
    }

    private func presentAlertIfNeeded() {
        // An alert UIKit refused never becomes its presenter's presented controller. Forget it rather
        // than wait for it to be deallocated, but keep one that is on screen or still on its way in.
        if let alert, alertPresenter?.presentedViewController !== alert, !alert.isBeingPresented {
            self.alert = nil
        }
        guard alert == nil, let configuration, let window = viewIfLoaded?.window else {
            return
        }
        var presenter = window.rootViewController
        while let presented = presenter?.presentedViewController, !presented.isBeingDismissed {
            presenter = presented
        }
        guard let presenter else {
            return
        }

        // UIKit drops a presentation requested while another one is still on its way in or out.
        let transitionCoordinator = presenter.transitionCoordinator
            ?? presenter.presentedViewController?.transitionCoordinator
        if let transitionCoordinator,
           transitionCoordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
               self?.presentOrDismissAlert()
           })
        {
            return
        }

        let alert = makeAlert(configuration)
        self.alert = alert
        alertPresenter = presenter
        presenter.present(alert, animated: true)
        guard presenter.presentedViewController !== alert else {
            hasRetriedPresentation = false
            return
        }
        // UIKit refused it without telling why, e.g. a transition requested earlier in this turn
        // hasn't started yet, so it has no coordinator to wait on. Ask once more on the next main
        // queue turn; after that, the next SwiftUI update or `viewDidAppear` asks again.
        guard !hasRetriedPresentation else {
            return
        }
        hasRetriedPresentation = true
        DispatchQueue.main.async { [weak self] in
            self?.presentOrDismissAlert()
        }
    }

    /// Return confirms, as it did in SwiftUI's alert. UIKit only does that for a `preferredAction`,
    /// which also restyles the buttons into a filled stack.
    private func submit(_ alert: UIAlertController?) {
        guard let alert, alert === self.alert, !alert.isBeingDismissed else {
            return
        }
        let enteredText = alert.textFields?.first?.text
        // Like a button tap: run the handler once the alert has finished dismissing.
        let dismisser = alertPresenter.flatMap { $0.presentedViewController === alert ? $0 : nil } ?? alert
        dismisser.dismiss(animated: true) { [weak self] in
            self?.handle(confirming: true, enteredText: enteredText)
        }
    }

    private func makeAlert(_ configuration: TextFieldAlertConfiguration) -> UIAlertController {
        let alert = UIAlertController(
            title: configuration.title,
            message: configuration.message,
            preferredStyle: .alert
        )
        alert.addTextField { [weak self, weak alert] textField in
            textField.placeholder = configuration.placeholder
            // Alert text fields don't capitalize by default, unlike other UIKit and SwiftUI text fields.
            textField.autocapitalizationType = .sentences
            textField.text = self?.text?.wrappedValue
            textField.addAction(
                UIAction { [weak self, weak textField] _ in
                    self?.text?.wrappedValue = textField?.text ?? ""
                },
                for: .editingChanged
            )
            textField.addAction(
                UIAction { [weak self, weak alert] _ in
                    self?.submit(alert)
                },
                for: .primaryActionTriggered
            )
        }
        alert.addAction(UIAlertAction(title: configuration.cancelTitle, style: .cancel) { [weak self, weak alert] _ in
            self?.handle(confirming: false, enteredText: alert?.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: configuration.confirmTitle, style: .default) { [weak self, weak alert] _ in
            self?.handle(confirming: true, enteredText: alert?.textFields?.first?.text)
        })
        return alert
    }
}

private struct TextFieldAlertPreview: View {
    @State var isPresented = false
    @State var name = ""
    @State var message: String?

    var body: some View {
        Button("Add Collection") {
            message = nil
            isPresented = true
        }
        .textFieldAlert(
            "Add Collection",
            isPresented: $isPresented,
            text: $name,
            placeholder: "Name",
            message: message,
            confirmTitle: "Add"
        ) {
            if name.localizedCaseInsensitiveCompare("Favorites") == .orderedSame {
                message = "\"\(name)\" is a reserved name."
                isPresented = true
            }
        }
    }
}

#Preview {
    TextFieldAlertPreview()
}
