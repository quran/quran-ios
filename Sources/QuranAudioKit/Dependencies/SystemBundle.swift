//
//  SystemBundle.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation

protocol SystemBundle: Sendable {
    func readArray(resource: String, withExtension: String) -> NSArray
}

struct DefaultSystemBundle: SystemBundle {
    func readArray(resource: String, withExtension: String) -> NSArray {
        let url = Bundle.main.url(forResource: resource, withExtension: withExtension)!
        return NSArray(contentsOf: url)!
    }
}
