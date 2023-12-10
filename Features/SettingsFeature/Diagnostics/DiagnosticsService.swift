//
//  DiagnosticsService.swift
//
//
//  Created by Mohamed Afifi on 2023-12-09.
//

import Foundation
import Preferences
import VLogging
import Zip

public struct DiagnosticsPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = DiagnosticsPreferences()

    @Preference(enableDebugLogging)
    public var enableDebugLogging: Bool

    public static func reset() {
        UserDefaults.standard.removeObject(forKey: enableDebugLogging.key)
    }

    // MARK: Private

    private static let enableDebugLogging = PreferenceKey<Bool>(key: "enableDebugLogging", defaultValue: false)
}

struct DiagnosticsService {
    struct DiagnosticsZip {
        let url: URL
        let cleanUp: () -> Void
    }

    // MARK: Internal

    let logsDirectory: URL
    let databasesDirectory: URL

    func buildDiagnosticsZip() throws -> DiagnosticsZip {
        let fileManager = FileManager.default

        // Prepare 'extras' directory.
        try? fileManager.removeItem(at: extras)
        try? fileManager.createDirectory(at: extras, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: extras) }

        try? saveUserDefaults()
        try? copyDatabases()

        // Create temporary file.
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileName = UUID().uuidString + ".zip"
        let zipFileURL = tempDirectoryURL.appendingPathComponent(fileName)

        // Zip 'Logs' directory.
        logger.info("Zip diagnostics to \(zipFileURL)")
        try Zip.zipFiles(paths: [logsDirectory], zipFilePath: zipFileURL, password: nil, progress: nil)
        logger.info("Diagnostics Zipped")

        return DiagnosticsZip(url: zipFileURL) {
            logger.info("Cleanup Diagnostics.")
            try? FileManager.default.removeItem(at: zipFileURL)
        }
    }

    // MARK: Private

    private var extras: URL {
        logsDirectory.appendingPathComponent("extras", isDirectory: true)
    }

    private func makeJSONSerializable(_ value: Any) -> Any {
        switch value {
        case let dataValue as Data:
            // Convert Data to Base64 encoded string
            return dataValue.base64EncodedString()
        case let dateValue as Date:
            // Convert Date to String
            let dateFormatter = ISO8601DateFormatter()
            return dateFormatter.string(from: dateValue)
        case let arrayValue as [Any]:
            // Recursively process each element in the array
            return arrayValue.map { makeJSONSerializable($0) }
        case let dictionaryValue as [String: Any]:
            return dictionaryValue.mapValues { makeJSONSerializable($0) }
        default:
            // Return the value as it is for serializable types
            return value
        }
    }

    private func saveUserDefaults() throws {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        let cleanedDictionary = makeJSONSerializable(dictionary)
        let data = try JSONSerialization.data(withJSONObject: cleanedDictionary, options: .prettyPrinted)
        let fileURL = extras.appendingPathComponent("UserDefaultsData.json")
        try data.write(to: fileURL, options: .atomicWrite)
    }

    private func copyDatabases() throws {
        let fileManager = FileManager.default

        // Get the databases directory contents
        let contents = try fileManager.contentsOfDirectory(at: databasesDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            let destinationFile = extras.appendingPathComponent(file.lastPathComponent)
            try? fileManager.copyItem(at: file, to: destinationFile)
        }
    }
}
