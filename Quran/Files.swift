//
//  Files.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
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

struct Files {

    static let audioExtension = "mp3"
    static let downloadResumeDataExtension = "resume"
    static let databaseRemoteFileExtension = "zip"
    static let databaseLocalFileExtension = "db"
    static let databasesPathComponent = "databases"
    static let translationsPathComponent = "translations"
    static let translationCompressedFileExtension = "zip"

    static let quarterPrefixArray = fileURL("quarter_prefix_array", withExtension: "plist")
    static let readers = fileURL("readers", withExtension: "plist")

    static let ayahInfoPath: String = filePath("images_\(quranImagesSize)/databases/ayahinfo_\(quranImagesSize)", ofType: "db")
    static let quranTextPath = filePath("images_\(quranImagesSize)/databases/quran.ar", ofType: "db")

    static let databasesPath: String = FileManager.documentsPath.stringByAppendingPath(databasesPathComponent)
    static let translationsURL = FileManager.documentsURL.appendingPathComponent(translationsPathComponent)
}

private func fileURL(_ fileName: String, withExtension `extension`: String) -> URL {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: `extension`) else {
        fatalError("Couldn't find file `\(fileName).\(`extension`)` locally ")
    }
    return url
}

private func filePath(_ fileName: String, ofType type: String) -> String {
    guard let path = Bundle.main.path(forResource: fileName, ofType: type) else {
        fatalError("Couldn't find file `\(fileName).\(type)` locally ")
    }
    return path
}

extension Qari {
    func localFolder() -> URL {
        return FileManager.documentsURL.appendingPathComponent(path)
    }
}

extension URL {
    func resumeURL() -> URL {
        return appendingPathExtension(Files.downloadResumeDataExtension)
    }
}

extension String {
    var resumePath: String {
        return stringByAppendingExtension(Files.downloadResumeDataExtension)
    }
}
