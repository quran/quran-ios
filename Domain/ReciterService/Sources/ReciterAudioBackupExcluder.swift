//
//  ReciterAudioBackupExcluder.swift
//  Quran
//
//  Created by Abdullah Levin on 2026-09-07.
//

import Foundation
import QuranAudio
import SystemDependencies
import VLogging

/// Keeps downloaded recitations out of device backups.
///
/// Audio is reproducible by downloading it again, so backing it up inflates the
/// user's iCloud storage and slows down restoring a device for no benefit.
public struct ReciterAudioBackupExcluder: Sendable {
    // MARK: Lifecycle

    public init(fileSystem: FileSystem = DefaultFileSystem()) {
        self.fileSystem = fileSystem
    }

    // MARK: Public

    /// Marks the audio files directory as excluded from backup, which covers the
    /// recitations already inside it as well as the ones downloaded later.
    public func excludeAudioFilesFromBackup() {
        let audioFiles = Reciter.audioFiles
        do {
            try fileSystem.createDirectory(at: audioFiles, withIntermediateDirectories: true)
            try fileSystem.setExcludedFromBackup(true, at: audioFiles)
        } catch {
            logger.error("Couldn't exclude audio files from backup. Error: \(error)")
        }
    }

    // MARK: Private

    private let fileSystem: FileSystem
}
