//
//  Reciter+URLs.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import Foundation
import QuranKit
import Utilities

extension Reciter {
    static let audioRemotePath = "hafs/databases/audio/"

    public var localDatabaseURL: URL? {
        guard case .gapless(let databaseName) = audioType else {
            return nil
        }
        let baseFileName = localFolder().appendingPathComponent(databaseName)
        return baseFileName.appendingPathExtension(Files.databaseLocalFileExtension)
    }

    public var localZipURL: URL? {
        guard case .gapless(let databaseName) = audioType else {
            return nil
        }
        let baseFileName = localFolder().appendingPathComponent(databaseName)
        return baseFileName.appendingPathExtension(Files.databaseRemoteFileExtension)
    }

    public static var audioFiles: URL {
        FileManager.documentsURL.appendingPathComponent(Files.audioFilesPathComponent, isDirectory: true)
    }

    var relativePath: String {
        Files.audioFilesPathComponent.stringByAppendingPath(directory)
    }

    public func localFolder() -> URL {
        FileManager.documentsURL.appendingPathComponent(relativePath, isDirectory: true)
    }

    // TODO: should be internal
    public func oldLocalFolder() -> URL {
        FileManager.documentsURL.appendingPathComponent(directory, isDirectory: true)
    }

    public func databaseRemoteURL(baseURL: URL) -> URL? {
        guard case AudioType.gapless(let databaseFileName) = audioType else {
            return nil
        }

        let audioDatabaseURL = baseURL.appendingPathComponent(Self.audioRemotePath)
        return audioDatabaseURL.appendingPathComponent(databaseFileName)
            .appendingPathExtension(Files.databaseRemoteFileExtension)
    }

    public func remoteURL(sura: Sura) -> URL {
        let fileName = sura.suraNumber.as3DigitString()
        return audioURL.appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    public func localURL(sura: Sura) -> URL {
        let fileName = sura.suraNumber.as3DigitString()
        return localFolder().appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    public func remoteURL(ayah: AyahNumber) -> URL {
        let fileName = ayah.sura.suraNumber.as3DigitString() + ayah.ayah.as3DigitString()
        return audioURL.appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    public func localURL(ayah: AyahNumber) -> URL {
        let fileName = ayah.sura.suraNumber.as3DigitString() + ayah.ayah.as3DigitString()
        return localFolder().appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    public func isReciterDirectory(_ directoryURL: URL) -> Bool {
        directory == directoryURL.lastPathComponent
    }
}

private enum Files {
    static let audioExtension = "mp3"
    static let databaseRemoteFileExtension = "zip"
    static let databaseLocalFileExtension = "db"
    static let audioFilesPathComponent = "audio_files"
}
