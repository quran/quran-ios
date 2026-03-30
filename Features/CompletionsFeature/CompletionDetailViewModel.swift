//
//  CompletionDetailViewModel.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Combine
import CompletionService
import QuranKit
import SwiftUI
import VLogging

@MainActor
final class CompletionDetailViewModel: ObservableObject {
    // MARK: Lifecycle

    init(completion: Completion, service: CompletionService, navigateTo: @escaping (Page) -> Void) {
        self.completion = completion
        self.service = service
        self.navigateTo = navigateTo
    }

    // MARK: Internal

    @Published var completion: Completion
    @Published var bookmarks: [CompletionBookmark] = []
    @Published var progress: CompletionProgress?
    @Published var error: Error?
    @Published var isShowingRename = false

    func start() async {
        async let bookmarksTask: Void = subscribeToBookmarks()
        async let progressTask: Void = subscribeToProgress()
        await bookmarksTask
        await progressTask
    }

    func rename(to name: String) async {
        logger.info("CompletionDetail: rename \(completion.id)")
        do {
            try await service.renameCompletion(completion, to: name)
        } catch {
            self.error = error
        }
    }

    func finish() async {
        logger.info("CompletionDetail: finish \(completion.id)")
        do {
            try await service.finishCompletion(completion)
        } catch {
            self.error = error
        }
    }

    func setActive() async {
        logger.info("CompletionDetail: set active \(completion.id)")
        do {
            try await service.setActive(completion)
        } catch {
            self.error = error
        }
    }

    func deleteBookmark(_ bookmark: CompletionBookmark) async {
        logger.info("CompletionDetail: delete bookmark \(bookmark.id)")
        do {
            try await service.removeBookmark(bookmark)
        } catch {
            self.error = error
        }
    }

    func deleteCompletion() async {
        logger.info("CompletionDetail: delete completion \(completion.id)")
        do {
            try await service.deleteCompletion(completion)
        } catch {
            self.error = error
        }
    }

    func navigateTo(_ page: Page) {
        navigateTo(page)
    }

    // MARK: Private

    private let service: CompletionService
    private let navigateTo: (Page) -> Void
    private var cancellables: Set<AnyCancellable> = []

    private func subscribeToBookmarks() async {
        let sequence = service.bookmarks(for: completion).values()
        for await bookmarks in sequence {
            self.bookmarks = bookmarks
        }
    }

    private func subscribeToProgress() async {
        let sequence = service.progress(for: completion).values()
        for await progress in sequence {
            self.progress = progress
        }
    }
}
