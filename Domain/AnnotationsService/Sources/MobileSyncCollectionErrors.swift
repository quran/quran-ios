#if QURAN_SYNC
//
//  MobileSyncCollectionErrors.swift
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import MobileSync
import QuranAnnotations

/// Rethrows MobileSync's collection and text length errors as their QuranAnnotations errors.
func mapCollectionErrors<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await mapTextLengthLimit(operation)
    } catch let error as MobileSyncReadOnlyCollectionError {
        throw ReadOnlyCollectionError(collectionID: error.id)
    } catch let error as MobileSyncDuplicateCollectionNameError {
        throw DuplicateCollectionNameError(name: error.name)
    } catch let error as MobileSyncReservedCollectionNameError {
        throw ReservedCollectionNameError(name: error.name)
    }
}
#endif
