//
//  Error+Extension.swift
//
//
//  Created by Mohamed Afifi on 2023-12-19.
//

import Foundation

extension Error {
    public var isCancelled: Bool {
        if self is CancellationError {
            return true
        }

        do {
            throw self
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch {
            return false
        }
    }

    /// This error followed by the errors it wraps through `NSUnderlyingErrorKey`.
    ///
    /// Stops after `NSError.maximumUnderlyingErrorDepth` errors, in case an `NSError` subclass
    /// returns a chain that loops back on itself.
    public var underlyingErrorChain: [NSError] {
        var chain: [NSError] = []
        var current: NSError? = self as NSError
        while let error = current, chain.count < NSError.maximumUnderlyingErrorDepth {
            chain.append(error)
            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return chain
    }
}

extension NSError {
    /// Bounds the walk over `NSUnderlyingErrorKey` in `underlyingErrorChain`.
    static let maximumUnderlyingErrorDepth = 16

    /// Whether this error, ignoring any error it wraps, reports that the device is out of
    /// storage: Cocoa's `NSFileWriteOutOfSpaceError` or POSIX's `ENOSPC`.
    public var reportsOutOfSpace: Bool {
        switch domain {
        case NSCocoaErrorDomain:
            code == NSFileWriteOutOfSpaceError
        case NSPOSIXErrorDomain:
            code == Int(ENOSPC)
        default:
            false
        }
    }
}
