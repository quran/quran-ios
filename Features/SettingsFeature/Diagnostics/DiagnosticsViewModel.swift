//
//  DiagnosticsViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-12-10.
//

import Combine
import UIKit

@MainActor
final class DiagnosticsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(diagnosticsService: DiagnosticsService, navigationController: UINavigationController?) {
        self.diagnosticsService = diagnosticsService
        self.navigationController = navigationController
    }

    // MARK: Internal

    @Published var error: Error? = nil

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
    private weak var navigationController: UINavigationController?
}
