//
//  NSManagedObjectContext+Extensions.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/5/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import Crashing
import PromiseKit

public extension NSManagedObjectContext {
    /// Save a context, or handle the save error (for example, when there data inconsistency or low memory).
    func save(with context: String) throws {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            crasher.recordError(error, reason: "Error saving context '\(context)'")
            throw error
        }
    }

    func perform<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) -> Promise<T> {
        Promise { resolver in
            self.perform {
                do {
                    let value = try block(self)
                    resolver.fulfill(value)
                } catch {
                    resolver.reject(error)
                }
            }
        }
    }
}
