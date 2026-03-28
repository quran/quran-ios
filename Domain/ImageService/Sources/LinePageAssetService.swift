//
//  LinePageAssetService.swift
//
//
//  Created by Mohamed Afifi on 2026-03-28.
//

import Foundation
import LinePagePersistence
import QuranKit
import SystemDependencies
import UIKit

public enum LinePageAssetsResult {
    case available(LinePageAssets)
    case unavailable
}

public struct LinePageAssets {
    public struct LineImage {
        public init(lineNumber: Int, imageURL: URL, image: UIImage) {
            self.lineNumber = lineNumber
            self.imageURL = imageURL
            self.image = image
        }

        public let lineNumber: Int
        public let imageURL: URL
        public let image: UIImage
    }

    public enum SidelineDirection: String, Sendable {
        case up
        case down
    }

    public struct SidelineImage {
        public init(targetLine: Int, direction: SidelineDirection, imageURL: URL, image: UIImage) {
            self.targetLine = targetLine
            self.direction = direction
            self.imageURL = imageURL
            self.image = image
        }

        public let targetLine: Int
        public let direction: SidelineDirection
        public let imageURL: URL
        public let image: UIImage
    }

    public init(
        page: Page,
        ayahInfoDatabaseURL: URL,
        persistence: any LinePagePersistence,
        lines: [LineImage],
        sidelines: [SidelineImage]
    ) {
        self.page = page
        self.ayahInfoDatabaseURL = ayahInfoDatabaseURL
        self.persistence = persistence
        self.lines = lines
        self.sidelines = sidelines
    }

    public let page: Page
    public let ayahInfoDatabaseURL: URL
    public let persistence: any LinePagePersistence
    public let lines: [LineImage]
    public let sidelines: [SidelineImage]
}

public struct LinePageAssetService {
    // MARK: Lifecycle

    public init(readingDirectory: URL?, widthParameter: Int = 1440, fileSystem: FileSystem = DefaultFileSystem()) {
        self.init(
            readingDirectory: readingDirectory,
            widthParameter: widthParameter,
            requiredPageNumbers: Quran.hafsMadani1440.pages.map(\.pageNumber),
            fileSystem: fileSystem
        )
    }

    init(readingDirectory: URL?, widthParameter: Int, requiredPageNumbers: [Int], fileSystem: FileSystem) {
        self.readingDirectory = readingDirectory
        self.widthParameter = widthParameter
        self.requiredPageNumbers = requiredPageNumbers
        self.fileSystem = fileSystem
    }

    // MARK: Public

    public func isReadingAvailable() -> Bool {
        hasRequiredStructure()
    }

    public func hasRequiredStructure() -> Bool {
        guard let readingDirectory else {
            return false
        }
        guard fileSystem.fileExists(at: readingDirectory) else {
            return false
        }
        guard fileSystem.fileExists(at: ayahInfoDatabaseURL(in: readingDirectory)) else {
            return false
        }
        guard let firstPageNumber = requiredPageNumbers.first else {
            return true
        }

        return fileSystem.fileExists(
            at: lineImageURL(pageNumber: firstPageNumber, lineNumber: 1, in: readingDirectory)
        )
    }

    public func assetsForPage(_ page: Page) -> LinePageAssetsResult {
        guard let readingDirectory else {
            return .unavailable
        }
        guard fileSystem.fileExists(at: readingDirectory) else {
            return .unavailable
        }

        let ayahInfoDatabaseURL = ayahInfoDatabaseURL(in: readingDirectory)
        guard fileSystem.fileExists(at: ayahInfoDatabaseURL) else {
            return .unavailable
        }

        var lines: [LinePageAssets.LineImage] = []
        for lineNumber in 1 ... lineCount {
            let imageURL = lineImageURL(pageNumber: page.pageNumber, lineNumber: lineNumber, in: readingDirectory)
            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                return .unavailable
            }
            lines.append(LinePageAssets.LineImage(lineNumber: lineNumber, imageURL: imageURL, image: image))
        }

        return .available(
            LinePageAssets(
                page: page,
                ayahInfoDatabaseURL: ayahInfoDatabaseURL,
                persistence: GRDBLinePagePersistence(fileURL: ayahInfoDatabaseURL),
                lines: lines,
                sidelines: loadSidelines(pageNumber: page.pageNumber, in: readingDirectory)
            )
        )
    }

    // MARK: Private

    private let readingDirectory: URL?
    private let widthParameter: Int
    private let requiredPageNumbers: [Int]
    private let fileSystem: FileSystem

    private let lineCount = 15

    private func ayahInfoDatabaseURL(in readingDirectory: URL) -> URL {
        readingDirectory
            .appendingPathComponent("images_\(widthParameter)")
            .appendingPathComponent("databases")
            .appendingPathComponent("ayahinfo_\(widthParameter).db")
    }

    private func imagesURL(in readingDirectory: URL) -> URL {
        readingDirectory
            .appendingPathComponent("images_\(widthParameter)")
            .appendingPathComponent("width_\(widthParameter)")
    }

    private func lineImageURL(pageNumber: Int, lineNumber: Int, in readingDirectory: URL) -> URL {
        imagesURL(in: readingDirectory)
            .appendingPathComponent(String(pageNumber))
            .appendingPathComponent("\(lineNumber).png")
    }

    private func sidelinesDirectory(pageNumber: Int, in readingDirectory: URL) -> URL {
        imagesURL(in: readingDirectory)
            .appendingPathComponent(String(pageNumber))
            .appendingPathComponent("sidelines")
    }

    private func loadSidelines(pageNumber: Int, in readingDirectory: URL) -> [LinePageAssets.SidelineImage] {
        let directory = sidelinesDirectory(pageNumber: pageNumber, in: readingDirectory)
        guard fileSystem.fileExists(at: directory) else {
            return []
        }
        guard let files = try? fileSystem.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }

        let defaultDirection: LinePageAssets.SidelineDirection = pageNumber.isMultiple(of: 2) ? .down : .up

        return files
            .filter { $0.pathExtension.lowercased() == "png" }
            .compactMap { url in
                guard let image = UIImage(contentsOfFile: url.path) else {
                    return nil
                }
                let baseName = url.deletingPathExtension().lastPathComponent
                let sanitized = baseName.replacingOccurrences(of: "_up", with: "")
                    .replacingOccurrences(of: "_down", with: "")
                guard let targetLine = Int(sanitized) else {
                    return nil
                }

                let direction: LinePageAssets.SidelineDirection = if baseName.contains("_up") {
                    .up
                } else if baseName.contains("_down") {
                    .down
                } else {
                    defaultDirection
                }

                return LinePageAssets.SidelineImage(
                    targetLine: targetLine,
                    direction: direction,
                    imageURL: url,
                    image: image
                )
            }
            .sorted {
                if $0.targetLine == $1.targetLine {
                    return $0.imageURL.lastPathComponent < $1.imageURL.lastPathComponent
                }
                return $0.targetLine < $1.targetLine
            }
    }
}
