//
//  Files.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Files {

    static let AudioExtension = "mp3"
    static let DownloadResumeDataExtension = "resume"
    static let DatabaseRemoteFileExtension = "zip"
    static let DatabaseLocalFileExtension = "db"

    static let QuarterPrefixArray: Foundation.URL = fileURL("quarter_prefix_array", withExtension: "plist")
    static let Readers: Foundation.URL = fileURL("readers", withExtension: "plist")

    static var DocumentsFolder: Foundation.URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()
}

private func fileURL(_ fileName: String, withExtension: String) -> Foundation.URL {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: withExtension) else {
        fatalError("Couldn't find file `\(fileName).\(withExtension)` locally ")
    }
    return url
}

extension Qari {
    func localFolder() -> Foundation.URL {
        return Files.DocumentsFolder.appendingPathComponent(path)
    }
}

extension Foundation.URL {
    func resumeURL() -> Foundation.URL {
        return appendingPathExtension(Files.DownloadResumeDataExtension)
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
