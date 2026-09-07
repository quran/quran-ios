//
//  ReciterAudioBackupExcluderTests.swift
//
//
//  Created by Abdullah Levin on 2026-09-07.
//

import Foundation
import QuranAudio
import SystemDependenciesFake
import Utilities
import XCTest
@testable import ReciterService

final class ReciterAudioBackupExcluderTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        fileSystem = FileSystemFake()
        excluder = ReciterAudioBackupExcluder(fileSystem: fileSystem)
    }

    func testExcludesTheAudioDirectoryAndNothingElse() {
        fileSystem.files = [audioFiles, otherDirectory]

        excluder.excludeAudioFilesFromBackup()

        XCTAssertEqual(fileSystem.urlsExcludedFromBackup, [audioFiles])
    }

    func testCreatesTheAudioDirectoryWhenItIsMissing() {
        fileSystem.files = []

        excluder.excludeAudioFilesFromBackup()

        XCTAssertTrue(fileSystem.files.contains(audioFiles))
    }

    func testExcludesTheAudioDirectoryBeforeAnythingIsDownloaded() {
        fileSystem.files = []

        excluder.excludeAudioFilesFromBackup()

        XCTAssertEqual(fileSystem.urlsExcludedFromBackup, [audioFiles])
    }

    func testRepeatedRunsKeepTheDirectoryExcluded() {
        excluder.excludeAudioFilesFromBackup()
        excluder.excludeAudioFilesFromBackup()

        XCTAssertEqual(fileSystem.urlsExcludedFromBackup, [audioFiles])
    }

    // MARK: Private

    private var fileSystem: FileSystemFake!
    private var excluder: ReciterAudioBackupExcluder!

    private var audioFiles: URL { Reciter.audioFiles.url }
    private var otherDirectory: URL { FileManager.documentsURL.appendingPathComponent("translations", isDirectory: true) }
}
