//
//  DiagnosticsViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-12-10.
//

import Combine
import Localization
import UIKit

@MainActor
final class DiagnosticsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        diagnosticsService: DiagnosticsService,
        isDebugLoggingAlwaysEnabled: Bool,
        navigationController: UINavigationController?
    ) {
        self.diagnosticsService = diagnosticsService
        self.isDebugLoggingAlwaysEnabled = isDebugLoggingAlwaysEnabled
        self.navigationController = navigationController
    }

    // MARK: Internal

    @Published var error: Error? = nil

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
    private weak var navigationController: UINavigationController?
}
