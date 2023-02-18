//
//  Reading.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

import Foundation

public enum Reading: Int, CaseIterable {
    case hafs_1405 = 0

    public var title: String {
        "Title 1"
    }

    public var description: String {
        "Description 1"
    }

    public var properties: [String] {
        ["Property 1", "Property 2"]
    }

    public var imageName: String {
        "logo-lg-w"
    }
}
