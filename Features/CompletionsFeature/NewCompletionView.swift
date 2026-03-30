//
//  NewCompletionView.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Localization
import NoorUI
import SwiftUI

struct NewCompletionView: View {
    // MARK: Internal

    @Binding var isPresented: Bool
    let completionCount: Int
    let onStart: (String) async -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(
                        "e.g., Ramadan 2026",
                        text: $name
                    )
                } header: {
                    Text("Name (Optional)")
                }

                Section {
                    Text("Starting a new completion will set it as your active reading journey.")
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
            }
            .navigationTitle("New Completion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lAndroid("cancel")) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            let finalName = name.isEmpty ? defaultName : name
                            await onStart(finalName)
                            isPresented = false
                        }
                    }
                }
            }
        }
    }

    // MARK: Private

    @State private var name = ""

    private var defaultName: String {
        "Completion #\(completionCount + 1)"
    }
}
