//
//  MigrationView.swift
//  Quran
//
//  Created by AI Assistant on 12/2/25.
//

import Foundation
import NoorUI
import SwiftUI

struct MigrationView: View {
    @ObservedObject var viewModel: MigrationViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                ProgressView()

                Text(viewModel.titlesText)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
            }
        }
    }
}

@MainActor
final class MigrationViewModel: ObservableObject {
    @Published private(set) var titles: [String]

    init(titles: [String]) {
        self.titles = titles
    }

    func setTitles(_ titles: Set<String>) {
        let sanitized = titles.filter { !$0.isEmpty }
        self.titles = sanitized.sorted()
    }

    var titlesText: String {
        titles.joined(separator: "\n")
    }
}
