//
//  CompletionsViewModel.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Analytics
import Combine
import CompletionService
import QuranKit
import ReadingService
import SwiftUI
import VLogging

@MainActor
final class CompletionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(service: CompletionService, navigateTo: @escaping (Page) -> Void) {
        self.service = service
        self.navigateTo = navigateTo
    }

    // MARK: Internal

    @Published var completions: [Completion] = []
    @Published var error: Error?
    @Published var isShowingNewCompletion = false

    var quran: Quran { readingPreferences.reading.quran }

    func start() async {
        let sequence = readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [service] reading in
                service.completions(quran: reading.quran)
            }
            .switchToLatest()
            .values()

        for await completions in sequence {
            self.completions = completions.sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive { return lhs.isActive }
                if (lhs.finishedAt == nil) != (rhs.finishedAt == nil) { return lhs.finishedAt == nil }
                return lhs.startedAt > rhs.startedAt
            }
        }
    }

    func createCompletion(name: String) async {
        let defaultName = name.isEmpty ? defaultCompletionName() : name
        do {
            _ = try await service.createCompletion(name: defaultName, quran: quran)
        } catch {
            self.error = error
        }
    }

    func deleteCompletion(_ completion: Completion) async {
        logger.info("Completions: delete completion \(completion.id)")
        do {
            try await service.deleteCompletion(completion)
        } catch {
            self.error = error
        }
    }

    func renameCompletion(_ completion: Completion, to name: String) async {
        logger.info("Completions: rename completion \(completion.id)")
        do {
            try await service.renameCompletion(completion, to: name)
        } catch {
            self.error = error
        }
    }

    func progress(for completion: Completion) -> AnyPublisher<CompletionProgress, Never> {
        service.progress(for: completion)
    }

    func navigateToPage(_ page: Page) {
        navigateTo(page)
    }

    func completionDetail(for completion: Completion) -> CompletionDetailViewModel {
        CompletionDetailViewModel(
            completion: completion,
            service: service,
            navigateTo: navigateTo
        )
    }

    // MARK: Private

    private let service: CompletionService
    private let navigateTo: (Page) -> Void
    private let readingPreferences = ReadingPreferences.shared

    private func defaultCompletionName() -> String {
        let n = completions.count + 1
        return "Completion #\(n)"
    }
}
