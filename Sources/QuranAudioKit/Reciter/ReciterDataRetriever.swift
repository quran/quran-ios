//
//  ReciterDataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import PromiseKit

public struct ReciterDataRetriever {
    private static let reciters = Bundle.main.url(forResource: "reciters", withExtension: "plist")!

    public init() {
    }

    public func getReciters() -> Guarantee<[Reciter]> {
        DispatchQueue.global().async(.guarantee) {
            guard let array = NSArray(contentsOf: Self.reciters) else {
                fatalError("Couldn't load `\(Self.reciters)` file")
            }
            // swiftlint:disable force_cast
            let recitersArray = array as! [NSDictionary]
            let reciters: [Reciter] = recitersArray.map { item in
                Reciter(id: item["id"] as! Int,
                        nameKey: item["name"] as! String,
                        directory: item["path"] as! String,
                        audioURL: URL(validURL: item["url"] as! String),
                        audioType: Self.audioType(item["databaseName"] as! String),
                        hasGaplessAlternative: item["hasGaplessAlternative"] as! Bool,
                        category: Reciter.Category(rawValue: item["category"] as! String)!)
            }
            // swiftlint:enable force_cast

            return reciters.filter { reciter in
                !reciter.hasGaplessAlternative || reciter.localFolder().isReachable
            }
            .sorted {
                $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending
            }
        }
    }

    private static func audioType(_ db: String) -> AudioType {
        if db.isEmpty {
            return .gapped
        }
        return .gapless(databaseName: db)
    }
}

extension Reciter {
    public static var audioFiles: URL {
        FileManager.documentsURL.appendingPathComponent(Files.audioFilesPathComponent)
    }

    var path: String {
        Files.audioFilesPathComponent.stringByAppendingPath(directory)
    }

    // TODO: should be internal
    public func localFolder() -> URL {
        FileManager.documentsURL.appendingPathComponent(path)
    }

    // TODO: should be internal
    public func oldLocalFolder() -> URL {
        FileManager.documentsURL.appendingPathComponent(directory)
    }
}
