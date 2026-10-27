//
//  DiagnosticsView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-09.
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct DiagnosticsView: View {
    @StateObject var viewModel: DiagnosticsViewModel

    var body: some View {
        DiagnosticsViewUI(
            error: $viewModel.error,
            enableDebugLogging: $viewModel.enableDebugLogging,
            isDebugLoggingAlwaysEnabled: viewModel.isDebugLoggingAlwaysEnabled,
            enableDebugLoggingFooter: viewModel.enableDebugLoggingFooter,
            shareLog: { viewModel.shareLogs() }
        )
    }
}

private struct DiagnosticsViewUI: View {
    @Binding var error: Error?
    @Binding var enableDebugLogging: Bool
    let isDebugLoggingAlwaysEnabled: Bool
    let enableDebugLoggingFooter: String
    let shareLog: Action

    var body: some View {
        NoorList {
            NoorBasicSection {
                Text(l("diagnostics.details"))
                    .foregroundColor(Color.secondaryLabel)
                    .listRowBackground(Color.clear)
            }

            NoorBasicSection(footer: enableDebugLoggingFooter) {
                Toggle(isOn: $enableDebugLogging) {
                    Text(l("diagnostics.enable_debug_logs"))
                }
                .disabled(isDebugLoggingAlwaysEnabled)
            }

            NoorBasicSection {
                NoorListItem(
                    title: .text(l("diagnostics.share_app_logs")),
                    action: .sync { shareLog() }
                )
            }
        }
        .errorAlert(error: $error)
    }
}

#Preview {
    struct Container: View {
        @State var error: Error?
        @State var enableDebugLogging = true

        var body: some View {
            DiagnosticsViewUI(
                error: $error,
                enableDebugLogging: $enableDebugLogging,
                isDebugLoggingAlwaysEnabled: false,
                enableDebugLoggingFooter: l("diagnostics.enable_debug_logs.details"),
                shareLog: {}
            )
        }
    }
    return Container()
}
