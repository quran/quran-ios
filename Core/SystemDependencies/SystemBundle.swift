//
//  SystemBundle.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation

public protocol SystemBundle: Sendable {
    func readArray(resource: String, withExtension: String) -> NSArray
    func infoValue(forKey key: String) -> Any?
}

public struct DefaultSystemBundle: SystemBundle {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func readArray(resource: String, withExtension: String) -> NSArray {
        let url = Bundle.main.url(forResource: resource, withExtension: withExtension)!
        return NSArray(contentsOf: url)!
    }

    public func infoValue(forKey key: String) -> Any? {
        Bundle.main.object(forInfoDictionaryKey: key)
    }
}
