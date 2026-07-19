//
//  TestResource+Path.swift
//
//
//  Created by Mohamed Afifi on 2023-06-24.
//

import Foundation

public func testResourceURL(_ resource: String) -> URL {
    URL(validURL: "\(#filePath)/../../../../Domain/TestResources/test_data/\(resource)").standardized
}
