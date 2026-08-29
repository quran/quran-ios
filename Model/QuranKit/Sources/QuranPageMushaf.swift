//
//  QuranPageMushaf.swift
//

public enum QuranPageMushaf: Int16, Sendable {
    case madani1405 = 0
    case madani1440 = 1
    case indoPak = 2

    // MARK: Public

    public var quran: Quran {
        switch self {
        case .madani1405:
            .hafsMadani1405
        case .madani1440:
            .hafsMadani1440
        case .indoPak:
            .hafsIndoPak
        }
    }
}
