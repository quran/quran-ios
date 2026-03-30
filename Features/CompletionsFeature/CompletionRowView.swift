//
//  CompletionRowView.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Combine
import CompletionService
import NoorUI
import QuranKit
import SwiftUI

struct CompletionRowView: View {
    // MARK: Internal

    let completion: Completion
    let progressPublisher: AnyPublisher<CompletionProgress, Never>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(completion.name ?? "Completion")
                    .font(.body)
                Spacer()
                statusBadge
            }

            if let progress {
                ProgressView(value: progress.percentComplete)
                    .tint(progressColor)

                Text("\(progress.pagesRead) of \(progress.totalPages) pages read")
                    .font(.caption)
                    .foregroundColor(.secondaryLabel)
            }

            Text("Started \(completion.startedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundColor(.secondaryLabel)
        }
        .padding(.vertical, 4)
        .onReceive(progressPublisher) { progress = $0 }
    }

    // MARK: Private

    @State private var progress: CompletionProgress?

    private var progressColor: Color {
        completion.finishedAt != nil ? .gray : .blue
    }

    @ViewBuilder
    private var statusBadge: some View {
        if completion.finishedAt != nil {
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
