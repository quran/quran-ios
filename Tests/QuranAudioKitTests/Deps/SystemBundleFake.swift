//
//  SystemBundleFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation
@testable import QuranAudioKit

final class SystemBundleFake: SystemBundle {
    var arrays: [String: NSArray] = [:]

    func readArray(resource: String, withExtension: String) -> NSArray {
        arrays[resource + "." + withExtension]!
    }
}
