//
//  Translation+URLs.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import Utilities

private extension Translation {
    static let compressedFileExtension = "zip"
    static let translationsPathComponent = "translations"
    static let localTranslationsPath = RelativeFilePath(translationsPathComponent, isDirectory: true)
}

extension Translation {
    public static func isLocalTranslationPath(_ path: RelativeFilePath) -> Bool {
        localTranslationsPath.isParent(of: path)
    }

    public var localPath: RelativeFilePath {
        Self.localTranslationsPath.appendingPathComponent(fileName, isDirectory: false)
    }

    public var localFiles: [RelativeFilePath] {
        possibleFileNames.map {
            Translation.localTranslationsPath.appendingPathComponent($0, isDirectory: false)
        }
    }

    public var unprocessedLocalPath: RelativeFilePath {
        Translation.localTranslationsPath.appendingPathComponent(unprocessedFileName, isDirectory: false)
    }

    public var isUnprocessedFileZip: Bool {
        unprocessedFileName.hasSuffix(Translation.compressedFileExtension)
    }

    private var possibleFileNames: [String] {
        let unprocessedFileName = unprocessedFileName
        if unprocessedFileName != fileName {
            return [fileName, unprocessedFileName]
        }
        return [fileName]
    }

    var unprocessedFileName: String {
        if fileURL.absoluteString.hasSuffix(Self.compressedFileExtension) {
            return fileName.stringByDeletingPathExtension.stringByAppendingExtension(Self.compressedFileExtension)
        }
        return fileName
    }
}
