import AppIntents
import Foundation

/// App Shortcut phrases require a known set of values; arbitrary counts use a separate action.
@available(iOS 17.2, *)
enum ListeningPageAmount: String, AppEnum {
    case one
    case two
    case five
    case ten
    case twenty

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Listening Amount", table: "AppIntents")
    )

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .one: DisplayRepresentation(title: LocalizedStringResource("one page", table: "AppIntents")),
        .two: DisplayRepresentation(title: LocalizedStringResource("two pages", table: "AppIntents")),
        .five: DisplayRepresentation(title: LocalizedStringResource("five pages", table: "AppIntents")),
        .ten: DisplayRepresentation(title: LocalizedStringResource("ten pages", table: "AppIntents")),
        .twenty: DisplayRepresentation(title: LocalizedStringResource("twenty pages", table: "AppIntents")),
    ]

    var pageCount: Int {
        switch self {
        case .one: 1
        case .two: 2
        case .five: 5
        case .ten: 10
        case .twenty: 20
        }
    }
}
