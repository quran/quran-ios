//
//  Translation+URLs.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation

private extension Translation {
    static let compressedFileExtension = "zip"
    static let translationsPathComponent = "translations"
    static let localTranslationsURL = FileManager.documentsURL.appendingPathComponent(translationsPathComponent)
}

extension Translation {
    public static func isLocalTranslationURL(_ url: URL) -> Bool {
        localTranslationsURL.isParent(of: url)
    }

    public var localURL: URL {
        Self.localTranslationsURL.appendingPathComponent(fileName)
    }

    public var localFiles: [URL] {
        possibleFileNames.map {
            Translation.localTranslationsURL.appendingPathComponent($0)
        }
    }

    public var unprocessedLocalURL: URL {
        Translation.localTranslationsURL.appendingPathComponent(unprocessedFileName)
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
