//
//  Reciter+++.swift
//
//
//  Created by Mohamed Afifi on 2023-06-04.
//

import Foundation
import Localization
import QuranKit

extension Reciter {
    public var localizedName: String {
        l(nameKey, table: .readers)
    }
}

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

    // TODO: should be private/internal
    public var relativePath: String {
        Files.audioFilesPathComponent.stringByAppendingPath(directory)
    }

    // TODO: should be internal
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

    func remoteURL(sura: Sura) -> URL {
        let fileName = sura.suraNumber.as3DigitString()
        return audioURL.appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    public func localURL(sura: Sura) -> URL {
        let fileName = sura.suraNumber.as3DigitString()
        return localFolder().appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    func remoteURL(ayah: AyahNumber) -> URL {
        let fileName = ayah.sura.suraNumber.as3DigitString() + ayah.ayah.as3DigitString()
        return audioURL.appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }

    public func localURL(ayah: AyahNumber) -> URL {
        let fileName = ayah.sura.suraNumber.as3DigitString() + ayah.ayah.as3DigitString()
        return localFolder().appendingPathComponent(fileName)
            .appendingPathExtension(Files.audioExtension)
    }
}

private struct Files {
    static let audioExtension = "mp3"
    static let databaseRemoteFileExtension = "zip"
    static let databaseLocalFileExtension = "db"
    static let audioFilesPathComponent = "audio_files"
}
