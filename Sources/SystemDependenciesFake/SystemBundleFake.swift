//
//  SystemBundleFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation
import SystemDependencies

public final class SystemBundleFake: SystemBundle, @unchecked Sendable {

    public init() {}

    public var arrays: [String: NSArray] = [:]
    public func readArray(resource: String, withExtension: String) -> NSArray {
        arrays[resource + "." + withExtension]!
    }

    public var info: [String: Any] = [:]
    public func infoValue(forKey key: String) -> Any? {
        info[key]
    }
}
