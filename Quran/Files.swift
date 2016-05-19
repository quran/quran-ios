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

    static let QuarterPrefixArray: NSURL = fileURL("quarter_prefix_array", withExtension: "plist")
    static let Readers: NSURL = fileURL("readers", withExtension: "plist")

    static var DocumentsFolder: NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    }()
}

private func fileURL(fileName: String, withExtension: String) -> NSURL {
    guard let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: withExtension) else {
        fatalError("Couldn't find file `\(fileName).\(withExtension)` locally ")
    }
    return url
}

extension Qari {
    func localFolder() -> NSURL {
        return Files.DocumentsFolder.URLByAppendingPathComponent(path)
    }
}

extension NSURL {
    func resumeURL() -> NSURL {
        return URLByAppendingPathExtension(Files.DownloadResumeDataExtension)
    }
}

extension String {
    func stringByAppendingPath(path: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(path)
    }

    func stringByAppendingExtension(pathExtension: String) -> String {
        return (self as NSString).stringByAppendingPathExtension(pathExtension) ?? (self + "." + pathExtension)
    }
}
