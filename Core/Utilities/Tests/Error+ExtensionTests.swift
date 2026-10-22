//
//  Error+ExtensionTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
import XCTest
@testable import Utilities

final class ErrorExtensionTests: XCTestCase {
    // MARK: Underlying error chain

    func test_underlyingErrorChain_listsTheErrorThenTheErrorsItWraps() {
        let innermost = posixError(ENOSPC)
        let middle = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [NSUnderlyingErrorKey: innermost])
        let outer = URLError(.unknown, userInfo: [NSUnderlyingErrorKey: middle])

        let chain = outer.underlyingErrorChain

        XCTAssertEqual(chain.map(\.domain), [NSURLErrorDomain, NSCocoaErrorDomain, NSPOSIXErrorDomain])
        XCTAssertEqual(chain.map(\.code), [URLError.unknown.rawValue, NSFileWriteUnknownError, Int(ENOSPC)])
    }

    func test_underlyingErrorChain_ofAnErrorWrappingNothing_isTheError() {
        XCTAssertEqual(posixError(ENOSPC).underlyingErrorChain, [posixError(ENOSPC)])
    }

    func test_underlyingErrorChain_reachesTheMaximumDepth() {
        let chain = nestedError(depth: NSError.maximumUnderlyingErrorDepth).underlyingErrorChain

        XCTAssertEqual(chain.count, NSError.maximumUnderlyingErrorDepth)
        XCTAssertEqual(chain.last?.domain, NSPOSIXErrorDomain)
    }

    func test_underlyingErrorChain_stopsAtTheMaximumDepth() {
        // NSError copies its user info, so a plain chain can't refer back to itself. The depth
        // cap bounds the walk, so an error nested deeper than it is never inspected.
        let chain = nestedError(depth: NSError.maximumUnderlyingErrorDepth + 1).underlyingErrorChain

        XCTAssertEqual(chain.count, NSError.maximumUnderlyingErrorDepth)
        XCTAssertFalse(chain.contains { $0.domain == NSPOSIXErrorDomain })
    }

    func test_underlyingErrorChain_ofASelfReferencingError_stopsAtTheMaximumDepth() {
        let error = SelfReferencingError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)

        XCTAssertEqual(error.underlyingErrorChain.count, NSError.maximumUnderlyingErrorDepth)
    }

    // MARK: Out of space

    func test_fileWriteOutOfSpace_reportsOutOfSpace() {
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError).reportsOutOfSpace)
    }

    func test_noSpaceLeftOnDevice_reportsOutOfSpace() {
        XCTAssertTrue(posixError(ENOSPC).reportsOutOfSpace)
    }

    func test_noSuchFile_doesNotReportOutOfSpace() {
        XCTAssertFalse(posixError(ENOENT).reportsOutOfSpace)
    }

    func test_outOfSpaceCodesInAnotherDomain_doNotReportOutOfSpace() {
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: NSFileWriteOutOfSpaceError).reportsOutOfSpace)
        XCTAssertFalse(NSError(domain: "OtherDomain", code: Int(ENOSPC)).reportsOutOfSpace)
    }

    func test_errorWrappingNoSpaceLeftOnDevice_doesNotItselfReportOutOfSpace() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
            NSUnderlyingErrorKey: posixError(ENOSPC),
        ])

        XCTAssertFalse(error.reportsOutOfSpace)
    }

    // MARK: Private

    private func posixError(_ code: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }

    /// `ENOSPC` wrapped so that it's the `depth`th error in the chain.
    private func nestedError(depth: Int) -> NSError {
        var error = posixError(ENOSPC)
        for _ in 1 ..< depth {
            error = NSError(domain: "OtherDomain", code: 1, userInfo: [NSUnderlyingErrorKey: error])
        }
        return error
    }
}

/// An error that wraps itself, which `NSError` can't express through its initializer.
private final class SelfReferencingError: NSError {
    override var userInfo: [String: Any] {
        [NSUnderlyingErrorKey: self]
    }
}
