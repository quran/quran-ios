//
//  TranslationDeleterTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import SystemDependenciesFake
import TranslationServiceFake
import XCTest
@testable import TranslationService

class TranslationDeleterTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        localTranslationsFake = LocalTranslationsFake(useFactory: true)
        service = TranslationDeleter(
            databasesURL: LocalTranslationsFake.databasesURL,
            fileSystem: fileSystem
        )
    }

    override func tearDown() {
        super.tearDown()
        localTranslationsFake.tearDown()
        preferences.reset()
        localTranslationsFake = nil
        service = nil
    }

    func test_deleteDownloadedTranslation() async throws {
        let translation = TranslationTestData.khanTranslation
        XCTAssertNotNil(translation.installedVersion)
        try await localTranslationsFake.setTranslations([translation])
        XCTAssertEqual(preferences.selectedTranslations, [translation.id])

        let initialLocalTranslations = try await retriever.getLocalTranslations()
        XCTAssertEqual(initialLocalTranslations, [translation])

        let deletedTranslation = try await service.deleteTranslation(translation)

        var expected = translation
        expected.installedVersion = nil
        XCTAssertEqual(expected, deletedTranslation)
        XCTAssertEqual(fileSystem.removedItems, [expected.localPath.url])
        XCTAssertEqual(preferences.selectedTranslations, [])

        let localTranslations = try await retriever.getLocalTranslations()
        XCTAssertEqual(localTranslations, [expected])
    }

    func test_deleteDownloadedTranslationAndZip() async throws {
        let translation = TranslationTestData.sahihTranslation
        XCTAssertNotNil(translation.installedVersion)
        try await localTranslationsFake.setTranslations([translation])
        XCTAssertEqual(preferences.selectedTranslations, [translation.id])

        let initialLocalTranslations = try await retriever.getLocalTranslations()
        XCTAssertEqual(initialLocalTranslations, [translation])

        let deletedTranslation = try await service.deleteTranslation(translation)

        var expected = translation
        expected.installedVersion = nil
        XCTAssertEqual(expected, deletedTranslation)
        let zipURL = expected.localPath.deletingPathExtension().appendingPathExtension("zip")
        XCTAssertEqual(fileSystem.removedItems, [expected.localPath, zipURL].map(\.url))
        XCTAssertEqual(preferences.selectedTranslations, [])

        let localTranslations = try await retriever.getLocalTranslations()
        XCTAssertEqual(localTranslations, [expected])
    }

    func test_deleteNotDownloadedTranslation() async throws {
        var translation = TranslationTestData.khanTranslation
        translation.installedVersion = nil

        try await localTranslationsFake.insertTranslation(translation, installedVersion: nil, downloaded: false)
        XCTAssertEqual(preferences.selectedTranslations, [])

        let initialLocalTranslations = try await retriever.getLocalTranslations()
        XCTAssertEqual(initialLocalTranslations, [translation])

        let deletedTranslation = try await service.deleteTranslation(translation)

        XCTAssertEqual(translation, deletedTranslation)
        XCTAssertEqual(fileSystem.removedItems, [translation.localPath.url])
        XCTAssertEqual(preferences.selectedTranslations, [])

        let localTranslations = try await retriever.getLocalTranslations()
        XCTAssertEqual(localTranslations, [translation])
    }

    // MARK: Private

    private var service: TranslationDeleter!
    private var localTranslationsFake: LocalTranslationsFake!

    private let preferences = SelectedTranslationsPreferences.shared

    private let baseURL = URL(validURL: "http://example.com")

    private var retriever: LocalTranslationsRetriever {
        localTranslationsFake.retriever
    }

    private var fileSystem: FileSystemFake {
        localTranslationsFake.fileSystem
    }
}
