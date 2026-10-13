#if QURAN_SYNC
//
//  MobileSyncTextLengthLimit.swift
//

import Foundation
@preconcurrency import MobileSync
import QuranAnnotations

extension TextLengthLimitError {
    init?(mobileSyncError error: Error) {
        guard let exception = (error as NSError).userInfo["KotlinException"] as? TextLengthLimitException,
              let field = Field(exception.field),
              let bound = Bound(exception.bound)
        else {
            return nil
        }
        self.init(field: field, bound: bound, limit: Int(exception.limit))
    }
}

func mapTextLengthLimit<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch {
        if let textLengthLimitError = TextLengthLimitError(mobileSyncError: error) {
            throw textLengthLimitError
        }
        throw error
    }
}

private extension TextLengthLimitError.Field {
    init?(_ field: TextLengthField) {
        switch field {
        case .noteBody: self = .noteBody
        case .collectionName: self = .collectionName
        default: return nil
        }
    }
}

private extension TextLengthLimitError.Bound {
    init?(_ bound: TextLengthBound) {
        switch bound {
        case .tooShort: self = .tooShort
        case .tooLong: self = .tooLong
        default: return nil
        }
    }
}
#endif
