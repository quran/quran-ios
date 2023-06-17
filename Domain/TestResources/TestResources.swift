//
//  TestResources.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import Foundation

public enum TestResources {
    public static var testDataURL: URL {
        Bundle.module.url(forResource: "test_data", withExtension: "")!
    }

    public static func resourceURL(_ path: String) -> URL {
        Bundle.module.url(forResource: "test_data/" + path, withExtension: nil)!
    }
}
