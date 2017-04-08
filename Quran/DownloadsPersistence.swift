//
//  DownloadsPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
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

protocol DownloadsPersistence {
    func retrieveAll() throws -> [DownloadBatch]
    func retrieve(status: Download.Status) throws -> [DownloadBatch]

    func insert(batch: [Download]) throws -> [Download]

    func update(url: URL, newStatus status: Download.Status) throws
    func update(batches: [DownloadBatch], newStatus status: Download.Status) throws

    func delete(batchId: Int64) throws
}
