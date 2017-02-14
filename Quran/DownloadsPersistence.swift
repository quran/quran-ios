//
//  DownloadsPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

protocol DownloadsPersistence {
    func retrieveAll() throws -> [Download]
    func retrieve(urls: [URL]) throws -> [URL: Download]
    func insert(downloads: [Download]) throws
    func remove(url: URL) throws
}
