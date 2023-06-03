//
//  TestResources.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import Foundation

public struct TestResources {
    public static func resourceURL(_ path: String) -> URL {
        let components = path.components(separatedBy: ".")
        let resource = components.dropLast().joined(separator: ".")
        let ext = components.last!
        return Bundle.module.url(forResource: "test_data/" + resource, withExtension: ext)!
    }

    public static var testDataURL: URL {
        Bundle.module.url(forResource: "test_data", withExtension: "")!
    }
}
