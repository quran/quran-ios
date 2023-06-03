//
//  TranslationUnzipper.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import Utilities
import Zip

protocol TranslationUnzipper {
    func unzipIfNeeded(_ translation: Translation) throws
}

struct DefaultTranslationUnzipper: TranslationUnzipper {
    func unzipIfNeeded(_ translation: Translation) throws {
        // installed latest version
        guard translation.version != translation.installedVersion else {
            return
        }

        /* states:

         Is Zip, zip exists  , db exists
         false,  x           , false     // Not Downloaded
         false,  x           , true      // need to check version (might be download/updgrade)
         true,   false       , false     // Not Downloaded
         true,   false       , true      // need to check version (might be download/updgrade)
         true,   true        , false     // Unzip, delete zip, check version
         true,   true        , true      // Unzip, delete zip, check version | Probably upgrade
         */

        // unzip if needed
        let raw = translation.rawFileName
        let isZip = raw.hasSuffix(Translation.compressedFileExtension)
        if isZip {
            let zipFile = Translation.localTranslationsURL.appendingPathComponent(raw)
            if zipFile.isReachable {
                // delete the zip in both cases (success or failure)
                // success: to save space
                // failure: to redownload it again
                defer {
                    try? FileManager.default.removeItem(at: zipFile)
                }
                try attempt(times: 3) {
                    try Zip.unzipFile(zipFile, destination: Translation.localTranslationsURL, overwrite: true, password: nil, progress: nil)
                }
            }
        }
    }
}
