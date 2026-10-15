//
//  TranslationUnzipper.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import QuranText
import SystemDependencies
import Utilities

protocol TranslationUnzipper {
    func unzipIfNeeded(_ translation: Translation) throws
}

struct DefaultTranslationUnzipper: TranslationUnzipper {
    // MARK: Internal

    func unzipIfNeeded(_ translation: Translation) throws {
        // installed latest version
        guard translation.version != translation.installedVersion else {
            return
        }

        // states:
        //
        // Is Zip, zip exists  , db exists
        // false,  x           , false     // Not Downloaded
        // false,  x           , true      // need to check version (might be download/updgrade)
        // true,   false       , false     // Not Downloaded
        // true,   false       , true      // need to check version (might be download/updgrade)
        // true,   true        , false     // Unzip, delete zip, check version
        // true,   true        , true      // Unzip, delete zip, check version | Probably upgrade

        // unzip if needed
        if translation.isUnprocessedFileZip {
            let zipFile = translation.unprocessedLocalPath.url
            if zipFile.isReachable {
                // delete the zip in both cases (success or failure)
                // success: to save space
                // failure: to redownload it again
                defer {
                    try? FileManager.default.removeItem(at: zipFile)
                }
                try attempt(times: 3) {
                    try zipper.unzipFile(zipFile, destination: zipFile.deletingLastPathComponent(), overwrite: true)
                }
            }
        }
    }

    // MARK: Private

    private let zipper: Zipper = DefaultZipper()
}
