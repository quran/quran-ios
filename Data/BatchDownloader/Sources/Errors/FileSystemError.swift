//
//  FileSystemError.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
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
import Localization
import Utilities

public enum FileSystemError: Error {
    case noDiskSpace
    case unknown(Error)

    // MARK: Lifecycle

    /// Reports `noDiskSpace` when `error`, or an error it wraps through `NSUnderlyingErrorKey`,
    /// says the device is out of storage.
    public init(error: Error) {
        self.init(error: error, availableCapacity: nil)
    }

    /// Reports `noDiskSpace` when `isNoDiskSpace(_:availableCapacity:)` classifies `error` as
    /// the device being out of storage.
    init(error: Error, availableCapacity: @autoclosure () -> Int?) {
        self = Self.isNoDiskSpace(error, availableCapacity: availableCapacity()) ? .noDiskSpace : .unknown(error)
    }

    // MARK: Internal

    /// Whether a download that failed with `error` failed because the device is out of storage.
    ///
    /// An error that reports a full device, directly or through `NSUnderlyingErrorKey`, always
    /// counts. An ambiguous file error counts only when the volume has less than
    /// `FileManager.lowAvailableCapacity` free. Older iOS releases failed background downloads
    /// with `ENOENT` when the disk was full, while iOS 27 fails them with `ENOSPC`. URLSession
    /// can also report `cannotCreateFile` or `cannotWriteToFile` without saying why.
    ///
    /// - Parameter availableCapacity: The free space, in bytes, of the volume holding the
    ///   downloads, from `FileManager.availableCapacity(at:)`, or `nil` if it couldn't be
    ///   read. Evaluated only for an ambiguous file error, so ordinary failures skip the disk.
    static func isNoDiskSpace(_ error: any Error, availableCapacity: @autoclosure () -> Int?) -> Bool {
        let chain = error.underlyingErrorChain
        if chain.contains(where: \.reportsOutOfSpace) {
            return true
        }
        guard chain.contains(where: mayReportNoDiskSpace), let availableCapacity = availableCapacity() else {
            return false
        }
        return availableCapacity < FileManager.lowAvailableCapacity
    }

    // MARK: Private

    /// File errors that a full device can cause, but that other failures cause too.
    private static func mayReportNoDiskSpace(_ error: NSError) -> Bool {
        switch error.domain {
        case NSPOSIXErrorDomain:
            error.code == Int(ENOENT)
        case NSURLErrorDomain:
            error.code == NSURLErrorCannotCreateFile || error.code == NSURLErrorCannotWriteToFile
        default:
            false
        }
    }
}

extension FileSystemError: LocalizedError {
    public var errorDescription: String? {
        let text: String = switch self {
        case .unknown:
            l("error.message.general")
        case .noDiskSpace:
            l("error.message.no_disk_space")
        }
        return text
    }
}
