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
            shareLog: { viewModel.shareLogs() }
        )
    }
}

private struct DiagnosticsViewUI: View {
    @Binding var error: Error?
    @Binding var enableDebugLogging: Bool
    let shareLog: AsyncAction

    var body: some View {
        NoorList {
            NoorBasicSection {
                Text(l("diagnostics.details"))
                    .foregroundColor(Color.secondaryLabel)
                    .listRowBackground(Color.clear)
            }

            NoorBasicSection(footer: l("diagnostics.enable_debug_logs.details")) {
                Toggle(isOn: $enableDebugLogging) {
                    Text(l("diagnostics.enable_debug_logs"))
                }
            }

            NoorBasicSection {
                NoorListItem(
                    title: .text(l("diagnostics.share_app_logs")),
                    action: shareLog
                )
            }
        }
        .errorAlert(error: $error)
    }
}

struct DiagnosticsView_Previews: PreviewProvider {
    struct Container: View {
        @State var error: Error?
        @State var enableDebugLogging = true

        var body: some View {
            DiagnosticsViewUI(
                error: $error,
                enableDebugLogging: $enableDebugLogging,
                shareLog: {}
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container()
        }
    }
}
