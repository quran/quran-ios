//
//  DefaultZipperTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import SystemDependencies
import XCTest
import ZIPFoundation

final class DefaultZipperTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
        try super.tearDownWithError()
    }

    func test_unzipFile_extractsEntriesIntoDestination() throws {
        let zipFile = try makeZip(["text.txt": "text", "folder/": nil, "folder/database.db": "database"])

        try sut.unzipFile(zipFile, destination: destination, overwrite: true)

        XCTAssertEqual(try contents(of: "text.txt"), "text")
        XCTAssertEqual(try contents(of: "folder/database.db"), "database")
    }

    func test_unzipFile_overwrite_replacesExistingFilesAndKeepsOthers() throws {
        try write("old", to: destination.appendingPathComponent("database.db"))
        try write("unrelated", to: destination.appendingPathComponent("other.db"))
        let zipFile = try makeZip(["database.db": "new"])

        try sut.unzipFile(zipFile, destination: destination, overwrite: true)

        XCTAssertEqual(try contents(of: "database.db"), "new")
        XCTAssertEqual(try contents(of: "other.db"), "unrelated")
    }

    func test_unzipFile_withoutOverwrite_failsOnExistingFile() throws {
        try write("old", to: destination.appendingPathComponent("database.db"))
        let zipFile = try makeZip(["database.db": "new"])

        XCTAssertThrowsError(try sut.unzipFile(zipFile, destination: destination, overwrite: false))

        XCTAssertEqual(try contents(of: "database.db"), "old")
    }

    // Regression for CVE-2023-39135: a `../` entry must not escape the destination.
    func test_unzipFile_rejectsEntriesOutsideDestination() throws {
        for entry in ["../escaped.txt", "folder/../../escaped.txt", "/../escaped.txt"] {
            let zipFile = try makeZip([entry: "escaped"])

            for overwrite in [true, false] {
                XCTAssertThrowsError(try sut.unzipFile(zipFile, destination: destination, overwrite: overwrite), entry)
                XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("escaped.txt").path), entry)
            }
        }
    }

    func test_unzipFile_overwrite_keepsFilesOutsideDestination() throws {
        let outsideFile = root.appendingPathComponent("outside.txt")
        try write("keep", to: outsideFile)
        let zipFile = try makeZip(["inside.txt": "inside", "../outside.txt": "replaced"])

        XCTAssertThrowsError(try sut.unzipFile(zipFile, destination: destination, overwrite: true))

        XCTAssertEqual(try String(contentsOf: outsideFile, encoding: .utf8), "keep")
    }

    // MARK: Private

    private let sut = DefaultZipper()
    private var root: URL!
    private var destination: URL!

    /// Builds a zip whose entries are written verbatim; a `nil` value adds a directory entry.
    private func makeZip(_ entries: KeyValuePairs<String, String?>) throws -> URL {
        let zipFile = root.appendingPathComponent(UUID().uuidString + ".zip")
        let archive = try Archive(url: zipFile, accessMode: .create)
        for (path, content) in entries {
            let data = Data((content ?? "").utf8)
            try archive.addEntry(
                with: path,
                type: content == nil ? .directory : .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .deflate
            ) { position, size in
                data.subdata(in: Int(position) ..< Int(position) + size)
            }
        }
        return zipFile
    }

    private func write(_ content: String, to url: URL) throws {
        try Data(content.utf8).write(to: url)
    }

    private func contents(of path: String) throws -> String {
        try String(contentsOf: destination.appendingPathComponent(path), encoding: .utf8)
    }
}
