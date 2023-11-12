//
//  FileSystemMigrator.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppMigrator
import Foundation
import Localization
import ReciterService
import Utilities

public struct FileSystemMigrator: Migrator {
    // MARK: Lifecycle

    public init(databasesURL: URL, recitersRetreiver: ReciterDataRetriever) {
        self.databasesURL = databasesURL
        self.recitersRetreiver = recitersRetreiver
    }

    // MARK: Public

    public var blocksUI: Bool { true }
    public var uiTitle: String? { l("update.filesystem.title") }

    public func execute(update: LaunchVersionUpdate) async {
        await arrangeFiles()
    }

    // MARK: Private

    private let databasesURL: URL
    private let recitersRetreiver: ReciterDataRetriever

    private func arrangeFiles() async {
        // move databases
        move(FileManager.documentsPath.stringByAppendingPath("last_pages.db"), to: databasesURL.path.stringByAppendingPath("last_pages.db"))
        move(FileManager.documentsPath.stringByAppendingPath("bookmarks.db"), to: databasesURL.path.stringByAppendingPath("bookmarks.db"))

        // move audio files
        let reciters = await recitersRetreiver.getReciters()
        for reciter in reciters {
            move(reciter.oldLocalFolder().url, to: reciter.localFolder().url)
        }
    }

    private func move(_ source: String, to desitnation: String) {
        let sourceURL = URL(fileURLWithPath: source)
        let desitnationURL = URL(fileURLWithPath: desitnation)
        move(sourceURL, to: desitnationURL)
    }

    private func move(_ source: URL, to destination: URL) {
        let fileManager = FileManager.default

        let destinationDir = destination.deletingLastPathComponent()
        try? fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        try? fileManager.moveItem(at: source, to: destination)
    }
}
