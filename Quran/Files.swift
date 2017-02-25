//
//  Files.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Files {

    static let audioExtension = "mp3"
    static let downloadResumeDataExtension = "resume"
    static let databaseRemoteFileExtension = "zip"
    static let databaseLocalFileExtension = "db"

    static let quarterPrefixArray = fileURL("quarter_prefix_array", withExtension: "plist")
    static let readers = fileURL("readers", withExtension: "plist")

    static let ayahInfoPath: String = filePath("images_\(quranImagesSize)/databases/ayahinfo_\(quranImagesSize)", ofType: "db")
    static let quranTextPath = filePath("images_\(quranImagesSize)/databases/quran.ar", ofType: "db")

    static let databasesPath: String = FileManager.default.documentsPath.stringByAppendingPath("databases")
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
        return FileManager.default.documentsURL.appendingPathComponent(path)
    }
}

extension URL {
    func resumeURL() -> URL {
        return appendingPathExtension(Files.downloadResumeDataExtension)
    }
}

extension String {
    func stringByAppendingPath(_ path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }

    func stringByAppendingExtension(_ pathExtension: String) -> String {
        return (self as NSString).appendingPathExtension(pathExtension) ?? (self + "." + pathExtension)
    }
}
