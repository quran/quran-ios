//
//  Reciter+Fixture.swift
//
//
//  Created by Mohammad Abdurraafay on 2023-02-11.
//

import Foundation
@testable import QuranAudioKit

extension Reciter {
    static let baseURL = URL(validURL: "http://example.com")
    static let gaplessDatabaseName = "mishari_alafasy"

    static var gappedReciter: Reciter {
        Reciter(id: 11,
                nameKey: "reciter1",
                directory: "reciter1",
                audioURL: baseURL.appendingPathComponent("reciter1"),
                audioType: .gapped,
                hasGaplessAlternative: false,
                category: .arabic)
    }

    static var gaplessReciter: Reciter {
        Reciter(id: 22,
                nameKey: "qari_afasy_gapless",
                directory: "mishari_alafasy",
                audioURL: baseURL.appendingPathComponent("mishari_alafasy"),
                audioType: .gapless(databaseName: gaplessDatabaseName),
                hasGaplessAlternative: false,
                category: .arabic)
    }

    func toPlistDictionary() -> [String: Any] {
        let databaseName: String
        switch audioType {
        case .gapless(let db): databaseName = db
        case .gapped: databaseName = ""
        }
        return [
            "id": id,
            "name": nameKey,
            "path": directory,
            "url": audioURL.absoluteString,
            "databaseName": databaseName,
            "hasGaplessAlternative": hasGaplessAlternative,
            "category": category.rawValue,
        ]
    }
}
