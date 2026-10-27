//
//  DiagnosticsViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-12-10.
//

import Combine
import Localization
import SystemDependencies
import UIKit

@MainActor
final class DiagnosticsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        diagnosticsService: DiagnosticsService,
        isDebugLoggingAlwaysEnabled: Bool,
        bundle: SystemBundle,
        navigationController: UINavigationController?
    ) {
        self.diagnosticsService = diagnosticsService
        self.isDebugLoggingAlwaysEnabled = isDebugLoggingAlwaysEnabled
        self.bundle = bundle
        self.navigationController = navigationController
    }

    // MARK: Internal

    @Published var error: Error? = nil

    /// The version and build, such as `2.4.0 (310)`, so a bug report can name the exact build.
    var appVersion: String {
        let version = bundle.infoValue(forKey: "CFBundleShortVersionString") as? String
        let build = (bundle.infoValue(forKey: "CFBundleVersion") as? String).map { "(\($0))" }
        let text = [version, build].compactMap { $0 }.joined(separator: " ")
        // Isolate it left to right, so right-to-left languages don't move the build before the version.
        return "\u{2066}\(text)\u{2069}"
    }

    var enableDebugLoggingFooter: String {
        isDebugLoggingAlwaysEnabled
            ? l("diagnostics.enable_debug_logs.always_on")
            : l("diagnostics.enable_debug_logs.details")
    }

    @Published var enableDebugLogging = DiagnosticsPreferences.shared.enableDebugLogging {
        didSet {
            DiagnosticsPreferences.shared.enableDebugLogging = enableDebugLogging
        }
    }

    func shareLogs() {
        do {
            let diagnosticsZip = try diagnosticsService.buildDiagnosticsZip()
            navigationController?.share([diagnosticsZip.url]) {
                diagnosticsZip.cleanUp()
            }
        } catch {
            self.error = error
        }
    }

    // MARK: Private

    private let diagnosticsService: DiagnosticsService
    private let isDebugLoggingAlwaysEnabled: Bool
    private let bundle: SystemBundle
    private weak var navigationController: UINavigationController?
}
