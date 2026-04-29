//
//  ReadingRemoteResourcesFake.swift
//
//
//  Created by Mohamed Afifi on 2023-11-22.
//

import Foundation
import QuranKit
import ReadingService

final class ReadingRemoteResourcesFake: ReadingRemoteResources {
    var versions: [Reading: Int] = [:]
    var urls: [Reading: String] = [:]

    func resource(for reading: Reading) -> RemoteResource? {
        let defaultURL: String? = {
            switch reading {
            case .hafs_1405:
                return nil
            case .hafs_1421:
                return "https://quran.com/hafs_1421.zip"
            case .hafs_1440:
                return "https://quran.com/hafs_1440.zip"
            case .hafs_1439:
                return "https://quran.com/hafs_1439.zip"
            case .hafs_1441:
                return "https://quran.com/hafs_1441.zip"
            case .tajweed:
                return "https://quran.com/tajweed.zip"
            case .naskh:
                return "https://quran.com/naskh.zip"
            }
        }()

        let url = urls[reading] ?? defaultURL
        let version = versions[reading] ?? 0
        return url.map { RemoteResource(url: URL(validURL: $0), reading: reading, version: version) }
    }
}
