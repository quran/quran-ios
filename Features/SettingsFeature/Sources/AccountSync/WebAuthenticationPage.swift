#if QURAN_SYNC
//
//  WebAuthenticationPage.swift
//
//
//  Created by Mohamed Afifi on 2026-11-05.
//

import AuthenticationServices
import UIKit
import VLogging

/// Shows a Quran.com page in a web authentication session, which shares Safari's cookie store with MobileSync's sign-in.
/// The page shows the user signed in only while that sign-in ran non-ephemeral and its persistent quran.com cookies are
/// valid; if sign-in ever becomes ephemeral, this page opens signed out again.
@MainActor
final class WebAuthenticationPage {
    // MARK: Internal

    /// Opens `url` over `window`, keeping the session until the user closes the page, then calls `onClose` with
    /// whether the page was shown; it wasn't when the session failed to start. Does nothing while a page is open.
    func open(_ url: URL, over window: UIWindow, onClose: @escaping @MainActor (_ wasShown: Bool) -> Void) {
        // A second session would cancel the first, whose ending would then release the second.
        guard session == nil else {
            logger.info("Account & Sync: a web session is already open")
            return
        }
        let presentationContext = WindowPresentationContext(window: window)
        // The page never redirects to a callback, so the session ends only when the user taps Cancel. The scheme is
        // one nothing registers or redirects to, so no page can end the session early. The iOS 15 deployment target
        // needs this initializer; the `callback:` one is iOS 17.4+.
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: Self.callbackURLScheme) { [weak self] _, error in
            Task { @MainActor in
                Self.logEnding(error)
                self?.close()
                onClose(true)
            }
        }
        // Non-ephemeral on purpose, to share the sign-in cookies.
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = presentationContext
        self.session = session
        self.presentationContext = presentationContext

        guard session.start() else {
            logger.error("Account & Sync: failed to start the web session for \(url)")
            close()
            onClose(false)
            return
        }
    }

    // MARK: Private

    private static let callbackURLScheme = "com.quran.ios.manage-account"

    private var session: ASWebAuthenticationSession?
    private var presentationContext: WindowPresentationContext?

    /// Every ending means the user closed the page; tapping Cancel reports a cancelled login.
    private static func logEnding(_ error: Error?) {
        if let error, (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin {
            logger.error("Account & Sync: the web session ended with an error: \(error)")
        } else {
            logger.info("Account & Sync: the user closed the web session")
        }
    }

    private func close() {
        session = nil
        presentationContext = nil
    }
}

/// Presents a web authentication session over a window.
@MainActor
private final class WindowPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    // MARK: Lifecycle

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: Internal

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        window
    }

    // MARK: Private

    private let window: UIWindow
}
#endif
