//
//  Zipper.swift
//
//
//  Created by Mohamed Afifi on 2023-11-22.
//

import Foundation
import Zip

public protocol Zipper {
    func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool, password: String?) throws
}

public struct DefaultZipper: Zipper {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool, password: String?) throws {
        try Zip.unzipFile(zipFile, destination: destination, overwrite: overwrite, password: password)
    }
}
