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

    /// Free space, in bytes, below which an ambiguous file error counts as no disk space.
    ///
    /// A full device doesn't always report itself. Older iOS releases failed background
    /// downloads with `ENOENT` when the disk was full, while iOS 27 fails them with `ENOSPC`.
    /// URLSession can also report `cannotCreateFile` or `cannotWriteToFile` without saying why.
    /// A download writes megabytes, and iOS warns that storage is almost full well before
    /// 50 MB, so such a failure below this is far more likely the device than a missing file.
    static let lowAvailableCapacity = 50 * 1024 * 1024

    /// Bounds the walk over `NSUnderlyingErrorKey`, in case an `NSError` subclass returns a
    /// chain that loops back on itself.
    static let maximumUnderlyingErrorDepth = 16

    /// Whether a download that failed with `error` failed because the device is out of storage.
    ///
    /// An error that reports a full device, directly or through `NSUnderlyingErrorKey`, always
    /// counts. An ambiguous file error counts only when the volume is nearly full.
    ///
    /// - Parameter availableCapacity: The free space, in bytes, of the volume holding the
    ///   downloads, from `URLResourceValues.volumeAvailableCapacity`, or `nil` if it couldn't be
    ///   read. Evaluated only for an ambiguous file error, so ordinary failures skip the disk.
    static func isNoDiskSpace(_ error: any Error, availableCapacity: @autoclosure () -> Int?) -> Bool {
        let chain = errorChain(of: error)
        if chain.contains(where: reportsNoDiskSpace) {
            return true
        }
        guard chain.contains(where: mayReportNoDiskSpace), let availableCapacity = availableCapacity() else {
            return false
        }
        return availableCapacity < lowAvailableCapacity
    }

    // MARK: Private

    /// `error` followed by the errors it wraps through `NSUnderlyingErrorKey`.
    private static func errorChain(of error: any Error) -> [NSError] {
        var chain: [NSError] = []
        var current: NSError? = error as NSError
        while let error = current, chain.count < maximumUnderlyingErrorDepth {
            chain.append(error)
            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return chain
    }

    private static func reportsNoDiskSpace(_ error: NSError) -> Bool {
        switch error.domain {
        case NSCocoaErrorDomain:
            error.code == NSFileWriteOutOfSpaceError
        case NSPOSIXErrorDomain:
            error.code == Int(ENOSPC)
        default:
            false
        }
    }

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
