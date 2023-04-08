//
//  ReciterListToReciterAudioDownloadRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
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
import QuranKit
import VLogging

private struct AudioFileLists {
    let gapped: [ReciterAudioFile]
    let gapless: [ReciterAudioFile]
}

public struct ReciterListToReciterAudioDownloadRetriever {
    let fileListFactory: ReciterAudioFileListRetrievalFactory

    public init(baseURL: URL) {
        fileListFactory = DefaultReciterAudioFileListRetrievalFactory(baseURL: baseURL)
    }

    public func getReciterAudioDownloads(for reciters: [Reciter], quran: Quran) -> Guarantee<[ReciterAudioDownload]> {
        let suras = Set(quran.suras)
        // TODO: needs refactoring. createFileLists should be part of createAudioDownload and remove the parallel map.
        let fileLists = DispatchQueue.global().async(.promise) {
            self.createFileLists(for: reciters, quran: quran)
        }
        let recitersAndSuras = fileLists
            .map { fileLists in reciters.map { q in (q, suras, fileLists) } }
        return recitersAndSuras.parallelMap { reciter, suras, fileLists in
            self.createAudioDownload(for: reciter, suras: suras, fileLists: fileLists, quran: quran)
        }
    }

    private func createFileLists(for reciters: [Reciter], quran: Quran) -> AudioFileLists {
        let gapped = reciters.first(where: {
            if case .gapped = $0.audioType {
                return true
            }
            return false
        })

        let gapless = reciters.first(where: {
            if case .gapless = $0.audioType {
                return true
            }
            return false
        })

        let gappedList: [ReciterAudioFile]
        if let reciter = gapped {
            gappedList = fileListFactory.fileListRetrievalForReciter(reciter).get(for: reciter,
                                                                                  from: quran.firstVerse,
                                                                                  to: quran.lastVerse)
        } else {
            gappedList = []
        }

        let gaplessList: [ReciterAudioFile]
        if let reciter = gapless {
            gaplessList = fileListFactory.fileListRetrievalForReciter(reciter).get(for: reciter,
                                                                                   from: quran.firstVerse,
                                                                                   to: quran.lastVerse)
        } else {
            gaplessList = []
        }
        return AudioFileLists(gapped: gappedList, gapless: gaplessList)
    }

    private func createAudioDownload(for reciter: Reciter, suras: Set<Sura>, fileLists: AudioFileLists, quran: Quran) -> ReciterAudioDownload {
        // get the list of files for the entire Quran.
        let fileList: [ReciterAudioFile]
        switch reciter.audioType {
        case .gapped: fileList = fileLists.gapped
        case .gapless: fileList = fileLists.gapless
        }

        let manager = FileManager.default
        var filesDictionary = fileList.flatGroup { $0.local.lastPathComponent }

        let properties: [URLResourceKey] = [.fileSizeKey]

        guard let enumerator = manager.enumerator(at: reciter.localFolder(), includingPropertiesForKeys: properties, options: []) else {
            return ReciterAudioDownload(reciter: reciter,
                                        downloadedSizeInBytes: 0,
                                        downloadedSuraCount: 0,
                                        surasCount: quran.suras.count)
        }

        // sum the sizes of downloaded files
        var sizeInBytes: UInt64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set([.fileSizeKey]))
                sizeInBytes += UInt64(resourceValues.fileSize ?? 0)
                let path = fileURL.lastPathComponent
                filesDictionary[path] = nil
            } catch {
                logger.error("Unexpected error while getting resourceValues. Error: \(error)")
            }
        }

        // remove suras that we didn't find dowonloaded files for
        var suras = suras
        for (_, file) in filesDictionary {
            // remove the suras from being downloaded.
            // For gapless, that's enough.
            // for gapped, we consider if one ayah is not downloaded that the entire sura is not downloaded.
            if let file = file as? ReciterSuraAudioFile {
                suras.remove(file.sura)
            }
        }

        return ReciterAudioDownload(reciter: reciter,
                                    downloadedSizeInBytes: sizeInBytes,
                                    downloadedSuraCount: suras.count,
                                    surasCount: quran.suras.count)
    }
}

// TODO: Remove the following

private extension Guarantee where T: Collection {
    func parallelMap<U>(on q: DispatchQueue = .global(), execute body: @escaping (T.Iterator.Element) -> U) -> Guarantee<[U]> {
        then(on: q) { collection in
            Guarantee<[U]> { resolver in
                resolver(collection.parallelMap(body))
            }
        }
    }
}

private extension Collection {
    func parallelMap<T>(_ transform: (Element) -> T) -> [T] {
        var result = [T?](repeating: nil, count: count)

        result.withUnsafeMutableBufferPointer { pointer in
            DispatchQueue.concurrentPerform(iterations: count) { i in
                pointer[i] = transform(self[index(startIndex, offsetBy: i)])
            }
        }

        return result.map { $0! }
    }
}
