#if QURAN_SYNC
//
//  MobileSyncTextLengthLimit.swift
//
//  Created by Mohamed Afifi on 2026-10-13.
//

import MobileSync
import QuranAnnotations

extension TextLengthLimitError {
    init(_ error: MobileSyncTextLengthLimitError) {
        self.init(field: Field(error.field), bound: Bound(error.bound), limit: error.limit)
    }
}

func mapTextLengthLimit<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch let error as MobileSyncTextLengthLimitError {
        throw TextLengthLimitError(error)
    }
}

private extension TextLengthLimitError.Field {
    init(_ field: MobileSyncTextLengthLimitError.Field) {
        switch field {
        case .noteBody: self = .noteBody
        case .collectionName: self = .collectionName
        }
    }
}

private extension TextLengthLimitError.Bound {
    init(_ bound: MobileSyncTextLengthLimitError.Bound) {
        switch bound {
        case .tooShort: self = .tooShort
        case .tooLong: self = .tooLong
        }
    }
}
#endif
