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

struct QuranURLs {
    static var host: URL = URL(validURL: "http://android.quran.com/")
    static var audioDatabaseURL: URL = host.appendingPathComponent("data/databases/audio/")
}

public struct Files {

    public static let audioExtension = "mp3"
    public static let downloadResumeDataExtension = "resume"
    public static let databaseRemoteFileExtension = "zip"
    public static let databaseLocalFileExtension = "db"
    public static let databasesPathComponent = "databases"
    public static let translationsPathComponent = "translations"
    public static let translationCompressedFileExtension = "zip"

    public static let quarterPrefixArray = fileURL("quarter_prefix_array", withExtension: "plist")
    public static let readers = fileURL("readers", withExtension: "plist")

    public static let ayahInfoPath: String = filePath("images_\(quranImagesSize)/databases/ayahinfo_\(quranImagesSize)", ofType: "db")
    public static let quranTextPath = filePath("images_\(quranImagesSize)/databases/quran.ar", ofType: "db")

    public static let databasesPath: String = FileManager.documentsPath.stringByAppendingPath(databasesPathComponent)
    public static let translationsURL = FileManager.documentsURL.appendingPathComponent(translationsPathComponent)
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

extension URL {
    public func resumeURL() -> URL {
        return appendingPathExtension(Files.downloadResumeDataExtension)
    }
}

extension String {
    public var resumePath: String {
        return stringByAppendingExtension(Files.downloadResumeDataExtension)
    }
}
