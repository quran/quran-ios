//
//  CoreDataPersistentHistoryTokenStore.swift
//  Quran
//

import CoreData
import Foundation
import VLogging

struct CoreDataPersistentHistoryTokenStore {
    // MARK: Internal

    let fileURL: URL

    func load() -> NSPersistentHistoryToken? {
        guard let tokenData = try? Data(contentsOf: fileURL) else { return nil }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSPersistentHistoryToken.self,
                from: tokenData
            )
        } catch {
            logger.error("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            removeUnreadableToken()
            return nil
        }
    }

    func save(_ token: NSPersistentHistoryToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("###\(#function): Failed to write token data. Error = \(error)")
        }
    }

    // MARK: Private

    private func removeUnreadableToken() {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            logger.error("###\(#function): Failed to remove unreadable token data. Error = \(error)")
        }
    }
}
