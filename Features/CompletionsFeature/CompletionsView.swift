//
//  CompletionsView.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Combine
import CompletionService
import Localization
import NoorUI
import QuranKit
import SwiftUI
import UIx

struct CompletionsView: View {
    @StateObject var viewModel: CompletionsViewModel

    var body: some View {
        CompletionsViewUI(
            completions: viewModel.completions,
            isShowingNewCompletion: $viewModel.isShowingNewCompletion,
            error: $viewModel.error,
            progressPublisher: { viewModel.progress(for: $0) },
            detailViewModel: { viewModel.completionDetail(for: $0) },
            deleteAction: { await viewModel.deleteCompletion($0) },
            renameAction: { completion, name in await viewModel.renameCompletion(completion, to: name) },
            createAction: { name in await viewModel.createCompletion(name: name) },
            completionCount: viewModel.completions.count,
            start: { await viewModel.start() }
        )
    }
}

private struct CompletionsViewUI: View {
    // MARK: Internal

    let completions: [Completion]
    @Binding var isShowingNewCompletion: Bool
    @Binding var error: Error?
    let progressPublisher: (Completion) -> AnyPublisher<CompletionProgress, Never>
    let detailViewModel: (Completion) -> CompletionDetailViewModel
    let deleteAction: AsyncItemAction<Completion>
    let renameAction: (Completion, String) async -> Void
    let createAction: (String) async -> Void
    let completionCount: Int
    let start: AsyncAction

    var body: some View {
        Group {
            if completions.isEmpty {
                DataUnavailableView(
                    title: "No Completions",
                    text: "Start your first reading journey.",
                    image: .bookmark
                )
            } else {
                NoorList {
                    NoorSection(completions) { completion in
                        NavigationLink {
                            CompletionDetailView(viewModel: detailViewModel(completion))
                        } label: {
                            CompletionRowView(
                                completion: completion,
                                progressPublisher: progressPublisher(completion)
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await deleteAction(completion) }
                            } label: {
                                Label(lAndroid("delete"), systemImage: "trash")
                            }

                            Button {
                                renameTarget = completion
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .task { await start() }
        .errorAlert(error: $error)
        .sheet(isPresented: $isShowingNewCompletion) {
            NewCompletionView(
                isPresented: $isShowingNewCompletion,
                completionCount: completionCount,
                onStart: createAction
            )
        }
        .sheet(item: $renameTarget) { completion in
            RenameCompletionSheet(
                completion: completion,
                onSave: { name in await renameAction(completion, name) }
            )
        }
    }

    // MARK: Private

    @State private var renameTarget: Completion?
}

private struct RenameCompletionSheet: View {
    let completion: Completion
    let onSave: (String) async -> Void

    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave(name)
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear { name = completion.name ?? "" }
    }
}
