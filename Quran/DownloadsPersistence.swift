//
//  DownloadsPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

protocol DownloadsPersistence {
    func retrieveAll() throws -> [DownloadBatch]
    func retrieve(status: Download.Status) throws -> [DownloadBatch]

    func insert(batch: [Download]) throws

    func update(url: URL, newStatus status: Download.Status) throws
    func update(batches: [DownloadBatch], newStatus status: Download.Status) throws
}
