//
//  SearchViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import Analytics
import QuranResources
import QuranText
import QuranTextKit
import XCTest
@testable import SearchFeature

@MainActor
final class SearchViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        SearchRecentsService.shared.reset()
        databasesURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: databasesURL, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        SearchRecentsService.shared.reset()
        try? FileManager.default.removeItem(at: databasesURL)
        databasesURL = nil
        try await super.tearDown()
    }

    func test_start_keepsSearchResults_whenViewReappears() async {
        let term = "الرحمن"
        let sut = makeSUT()

        var task = Task { await sut.start() }
        await settle()
        sut.search(for: term)
        await waitUntil { sut.searchResults != nil }
        let results = sut.searchResults
        XCTAssertEqual(results?.isEmpty, false)

        // Leaving the screen cancels the view's task, and returning starts it again.
        task.cancel()
        await task.value
        task = Task { await sut.start() }
        defer { task.cancel() }
        await settle()

        XCTAssertEqual(sut.searchTerm, term)
        XCTAssertEqual(sut.searchResults, results)
    }

    // MARK: Private

    private var databasesURL: URL!

    private func makeSUT() -> SearchViewModel {
        SearchViewModel(
            analytics: NoopAnalytics(),
            searchService: CompositeSearcher(
                databasesURL: databasesURL,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            navigateTo: { _ in }
        )
    }

    private func settle(iterations: Int = 1000) async {
        for _ in 0 ..< iterations {
            await Task.yield()
        }
    }

    private func waitUntil(
        timeout: TimeInterval = 10,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private struct NoopAnalytics: AnalyticsLibrary {
    func logEvent(_ name: String, value: String) { }
}

private extension SearchViewModel {
    var searchResults: [SearchResults]? {
        switch searchState {
        case .searching: nil
        case .searchResult(let results): results
        }
    }
}
