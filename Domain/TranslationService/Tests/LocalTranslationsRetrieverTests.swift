//
//  LocalTranslationsRetrieverTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import SystemDependenciesFake
import TestUtilities
@testable import TranslationService
import XCTest

class LocalTranslationsRetrieverTests: XCTestCase {
    private var service: LocalTranslationsRetriever {
        localTranslationsFake.retriever
    }

    private var persistence: ActiveTranslationsPersistence {
        localTranslationsFake.persistence
    }

    private var fileSystem: FileSystemFake {
        localTranslationsFake.fileSystem
    }

    private var localTranslationsFake: LocalTranslationsFake!
    private let preferences = SelectedTranslationsPreferences.shared

    private let translations = [
        TranslationTestData.khanTranslation,
        TranslationTestData.sahihTranslation,
    ]

    override func setUp() {
        super.setUp()
        localTranslationsFake = LocalTranslationsFake(useFactory: true)
    }

    override func tearDown() {
        super.tearDown()
        localTranslationsFake.tearDown()
        preferences.reset()
        localTranslationsFake = nil
    }

    func test_retrievingLocalTranslations_allDownloaded() async throws {
        for translation in translations {
            try await localTranslationsFake.insertTranslation(
                translation, installedVersion: translation.version, downloaded: true
            )
        }

        let localTranslations = try await service.getLocalTranslations()
        XCTAssertEqual(Set(localTranslations), Set(translations))
    }

    func test_retrievingLocalTranslations_someDownloaded() async throws {
        var downloadedTranslation = translations[0]
        downloadedTranslation.installedVersion = downloadedTranslation.version

        var notDownloadedTranslation = translations[1]
        notDownloadedTranslation.installedVersion = nil

        let translations = [downloadedTranslation, notDownloadedTranslation]

        for translation in translations {
            try await persistence.insert(translation)
        }

        fileSystem.files = [downloadedTranslation.localURL]

        let localTranslations = try await service.getLocalTranslations()
        XCTAssertEqual(Set(localTranslations), Set(translations))
    }

    func test_retrievingLocalTranslations_deletedTranslation() async throws {
        try await localTranslationsFake.insertTranslation(
            translations[0], installedVersion: translations[0].version, downloaded: false
        )
        let expectedTranslation = expectedTranslation(translations[0], installedVersion: nil)

        let localTranslations = try await service.getLocalTranslations()
        XCTAssertEqual(Set(localTranslations), [expectedTranslation])
    }

    func test_retrievingLocalTranslations_initialDownload() async throws {
        try await localTranslationsFake.insertTranslation(
            translations[0], installedVersion: nil, downloaded: true
        )
        let expectedTranslation = expectedTranslation(translations[0], installedVersion: 5)

        let localTranslations = try await service.getLocalTranslations()
        XCTAssertEqual(Set(localTranslations), [expectedTranslation])
    }

    func test_retrievingLocalTranslations_upgradeDownloaded() async throws {
        try await localTranslationsFake.insertTranslation(
            translations[0], installedVersion: 2, downloaded: true
        )
        let expectedTranslation = expectedTranslation(translations[0], installedVersion: 5)

        let localTranslations = try await service.getLocalTranslations()
        XCTAssertEqual(Set(localTranslations), [expectedTranslation])
    }

    func test_retrievingLocalTranslations_errorAfterDownload() async throws {
        localTranslationsFake = LocalTranslationsFake(useFactory: false)
        try await localTranslationsFake.insertTranslation(
            translations[0], installedVersion: 2, downloaded: true
        )

        let expectedTranslation = expectedTranslation(translations[0], installedVersion: nil)

        XCTAssertTrue(preferences.isSelected(expectedTranslation.id))
        let localTranslations = try await service.getLocalTranslations()
        XCTAssertEqual(Set(localTranslations), [expectedTranslation])
        XCTAssertFalse(preferences.isSelected(expectedTranslation.id))
    }

    // MARK: - Helpers

    private func expectedTranslation(_ translation: Translation, installedVersion: Int?) -> Translation {
        var translation = translation
        translation.installedVersion = installedVersion
        return translation
    }
}
