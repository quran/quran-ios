//
//  RecitersPathMigrator.swift
//  Quran
//
//  Created by Mohamed Afifi on 2021-12-07.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import AppMigrator
import Foundation
import Localization
import QuranAudio
import Utilities

public struct RecitersPathMigrator: Migrator {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var blocksUI: Bool { true }
    public var uiTitle: String? { l("update.filesystem.title") }

    public func execute(update: LaunchVersionUpdate) async {
        arrangeFiles()
    }

    // MARK: Private

    private func arrangeFiles() {
        // move reciters to Android paths
        move("18", to: "sa3d_alghamidi") // reciter_saad_al_ghamidi_gapless
        move("mishari_alafasy_cali", to: "mishari_cali") // reciter_afasy_cali_gapless
        move("ahmed_al3ajamy", to: "ahmed_alajamy") // reciter_ajamy_gapless
        move("maher_al_muaiqly", to: "muaiqly_kfgqpc") // reciter_muaiqly_gapless
    }

    private func move(_ sourcePath: String, to destinationPath: String) {
        let source = Reciter.audioFiles.appendingPathComponent(sourcePath, isDirectory: true)
        let destination = Reciter.audioFiles.appendingPathComponent(destinationPath, isDirectory: true)

        let fileManager = FileManager.default

        let destinationDir = destination.deletingLastPathComponent()
        try? fileManager.createDirectory(at: destinationDir.url, withIntermediateDirectories: true)
        try? fileManager.moveItem(at: source.url, to: destination.url)
    }
}
