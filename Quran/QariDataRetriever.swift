//
//  QariDataRetriever.swift
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

struct QariDataRetriever: DataRetriever {

    func retrieve(onCompletion: @escaping ([Qari]) -> Void) {
        Queue.background.async {
            guard let readersDictionary = NSDictionary(contentsOf: Files.readers) else {
                fatalError("Couldn't load `\(Files.readers)` file")
            }

            // get the values
            let ids: [Int] = get(from: readersDictionary, key: "quran_readers_id")
            let names: [String] = get(from: readersDictionary, key: "quran_readers_name")
            let haveGaplessEquivalents: [Bool] = get(from: readersDictionary, key: "quran_readers_have_gapless_equivalents")
            let localPaths: [String] = get(from: readersDictionary, key: "quran_readers_path")
            let databaseNames: [String] = get(from: readersDictionary, key: "quran_readers_db_name")
            let remoteURLs: [String] = get(from: readersDictionary, key: "quran_readers_urls")
            let images: [String] = get(from: readersDictionary, key: "quran_readers_image")

            // validate the array sizes
            validateSize(ids, names)
            validateSize(ids, haveGaplessEquivalents)
            validateSize(ids, localPaths)
            validateSize(ids, databaseNames)
            validateSize(ids, remoteURLs)
            validateSize(ids, images)

            precondition(Set(localPaths).count == localPaths.count, "quran_readers_path should have unique values")

            var qaris: [Qari] = []
            for i in 0..<names.count {

                precondition(i == ids[i], "Incorrect id")

                guard !haveGaplessEquivalents[i] else {
                    continue
                }

                let type: AudioType
                let databaseName = databaseNames[i]
                if databaseName.isEmpty {
                    type = .gapped
                } else {
                    type = .gapless(databaseName: databaseName)
                }

                let image = images[i]
                let imageName: String?
                if image.isEmpty {
                    imageName = nil
                } else {
                    imageName = image
                }

                let qari = Qari(
                    id: i,
                    name: NSLocalizedString(names[i], tableName: "Readers", comment: ""),
                    path: localPaths[i],
                    audioURL: URL(validURL: remoteURLs[i]),
                    audioType: type,
                    imageName: imageName)
                qaris.append(qari)
            }

            qaris.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            Queue.main.async {
                onCompletion(qaris)
            }
        }
    }
}

private func get<T>(from: NSDictionary, key: String) -> T {
    guard let value = from[key] as? T else {
        fatalError("Couldn't read \(key) from \(Files.readers)")
    }
    return value
}

private func validateSize<T, U>(_ first: [T], _ second: [U]) {
    precondition(first.count == second.count, "Incorrect readers array count")
}
