#if QURAN_SYNC
//
//  CollectionNameError.swift
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import QuranAnnotations

/// Why a typed collection name was rejected; the name alert shows it and keeps the name for editing.
enum CollectionNameError: Equatable {
    case textLength(TextLengthLimitError)
    case reserved(ReservedCollectionNameError)
    case duplicate(DuplicateCollectionNameError)

    // MARK: Lifecycle

    init?(_ error: Error) {
        switch error {
        case let error as TextLengthLimitError:
            self = .textLength(error)
        case let error as ReservedCollectionNameError:
            self = .reserved(error)
        case let error as DuplicateCollectionNameError:
            self = .duplicate(error)
        default:
            return nil
        }
    }

    // MARK: Internal

    /// Describes the rejection without the name, which may be private.
    var logDescription: String {
        switch self {
        case .textLength(let error):
            "bound: \(error.bound), limit: \(error.limit)"
        case .reserved:
            "reserved name"
        case .duplicate:
            "another collection has the name"
        }
    }
}
#endif
