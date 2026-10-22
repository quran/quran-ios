//
//  FileManager+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import VLogging

extension FileManager {
    public static let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    public static let documentsURL: URL = `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    public static let applicationSupport = `default`.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

    /// Free space, in bytes, below which an ambiguous storage failure counts as the device
    /// being out of storage.
    ///
    /// A full device doesn't always report itself. SQLite can fail to open a store with
    /// `SQLITE_CANTOPEN` or `SQLITE_IOERR` rather than `SQLITE_FULL`, and a download can fail
    /// with `ENOENT`, `cannotCreateFile`, or `cannotWriteToFile` rather than `ENOSPC`. Opening a
    /// store or writing a download needs a few MB, and iOS warns that storage is almost full
    /// well before 50 MB, so such a failure below this is far more likely the device than
    /// anything else. Each caller decides which of its failures are ambiguous.
    public static let lowAvailableCapacity = 50 * 1024 * 1024

    /// The free space, in bytes, on the volume holding `directory`, measured at its nearest
    /// existing ancestor, since the directory may not exist yet. Logs and returns `nil` if it
    /// can't be read.
    ///
    /// Reads real free space rather than the "important usage" capacity, which counts space
    /// the system could purge but nothing can write to yet.
    public func availableCapacity(at directory: URL) -> Int? {
        var existingDirectory = directory.standardizedFileURL
        while !fileExists(atPath: existingDirectory.path), existingDirectory.pathComponents.count > 1 {
            existingDirectory = existingDirectory.deletingLastPathComponent()
        }
        do {
            let values = try existingDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return values.volumeAvailableCapacity
        } catch {
            logger.error("Couldn't read the available capacity at \(existingDirectory.path). Error: \(error)")
            return nil
        }
    }

    public func removeDirectoryContents(at directory: URL) {
        let files = (try? contentsOfDirectory(atPath: directory.path)) ?? []
        for fileName in files {
            let filePath = directory.appendingPathComponent(fileName)
            try? removeItem(atPath: filePath.path)
        }
    }
}
