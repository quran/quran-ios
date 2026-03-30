//
//  CompletionDetailView.swift
//
//
//  Created by Selim on 29.03.2026.
//

import CompletionService
import Localization
import NoorUI
import QuranKit
import SwiftUI

struct CompletionDetailView: View {
    // MARK: Internal

    @StateObject var viewModel: CompletionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            summarySection
            statisticsSection
            historySection
            actionsSection
        }
        .navigationTitle(viewModel.completion.name ?? "Completion")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.start() }
        .sheet(isPresented: $viewModel.isShowingRename) {
            RenameSheet(
                currentName: viewModel.completion.name ?? "",
                onSave: { newName in
                    Task { await viewModel.rename(to: newName) }
                }
            )
        }
    }

    // MARK: Private

    @State private var showDeleteConfirmation = false
    @State private var showFinishConfirmation = false

    private var summarySection: some View {
        Section("Summary") {
            if let progress = viewModel.progress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.completion.name ?? "Completion")
                            .font(.headline)
                        Spacer()
                        statusBadge
                    }

                    ProgressView(value: progress.percentComplete)

                    HStack {
                        Text("\(progress.pagesRead) / \(progress.totalPages) pages")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0f%%", progress.percentComplete * 100))
                            .font(.subheadline)
                            .foregroundColor(.secondaryLabel)
                    }
                }
                .padding(.vertical, 4)
            }

            InfoRow(label: "Started", value: viewModel.completion.startedAt.formatted(date: .long, time: .omitted))

            if let finishedAt = viewModel.completion.finishedAt {
                InfoRow(label: "Finished", value: finishedAt.formatted(date: .long, time: .omitted))
            } else {
                InfoRow(label: "Status", value: "In Progress")
            }
        }
    }

    private var statisticsSection: some View {
        Section("Statistics") {
            if let progress = viewModel.progress {
                InfoRow(label: "Pages Read", value: "\(progress.pagesRead)")
                InfoRow(label: "Pages Remaining", value: "\(progress.pagesRemaining)")

                let days = Calendar.current.dateComponents([.day], from: viewModel.completion.startedAt, to: Date()).day ?? 0
                InfoRow(label: "Days Active", value: "\(days) days")

                if let avgTime = progress.averageTimePerPage, avgTime > 0 {
                    let pagesPerDay = 86400 / avgTime
                    InfoRow(label: "Avg. Pace", value: String(format: "%.1f pages/day", pagesPerDay))
                }

                if let finish = progress.estimatedFinishDate, viewModel.completion.finishedAt == nil {
                    InfoRow(label: "Est. Finish", value: finish.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    private var historySection: some View {
        Section("Reading History") {
            if viewModel.bookmarks.isEmpty {
                Text("No bookmarks yet.")
                    .foregroundColor(.secondaryLabel)
            } else {
                ForEach(viewModel.bookmarks) { bookmark in
                    let ayah = bookmark.page.firstVerse
                    NoorListItem(
                        image: .init(.bookmark, color: .red),
                        title: "\(ayah.sura.localizedName()) \(sura: ayah.sura.arabicSuraName)",
                        subtitle: .init(text: bookmark.createdAt.timeAgo(), location: .bottom),
                        accessory: .text(NumberFormatter.shared.format(bookmark.page.pageNumber))
                    ) {
                        viewModel.navigateTo(bookmark.page)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        Task { await viewModel.deleteBookmark(viewModel.bookmarks[index]) }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Rename") {
                viewModel.isShowingRename = true
            }

            if viewModel.completion.finishedAt == nil {
                Button("Mark as Finished") {
                    showFinishConfirmation = true
                }
                .confirmationDialog(
                    "Mark this completion as finished? You can still view its history.",
                    isPresented: $showFinishConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Mark as Finished", role: .destructive) {
                        Task { await viewModel.finish() }
                    }
                }
            }

            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
            .confirmationDialog(
                "Delete this completion? All associated bookmarks will also be deleted.",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteCompletion()
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if viewModel.completion.finishedAt != nil {
            Label("Finished", systemImage: "checkmark.circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            Text("In Progress")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue)
                .clipShape(Capsule())
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondaryLabel)
        }
    }
}

private struct RenameSheet: View {
    let currentName: String
    let onSave: (String) -> Void

    @State private var name: String = ""
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
                        onSave(name)
                        dismiss()
                    }
                }
            }
        }
        .onAppear { name = currentName }
    }
}
