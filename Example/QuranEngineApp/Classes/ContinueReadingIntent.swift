import AppIntents
import Foundation
import UIKit

@available(iOS 17.2, *)
struct ContinueReadingIntent: AppIntent {
    static let title = LocalizedStringResource("Continue Reading", table: "AppIntents")
    static let description = IntentDescription(
        LocalizedStringResource("Open the Quran at your last reading position.", table: "AppIntents")
    )

    static let openAppWhenRun = true

    @available(iOS 26.0, *)
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        // OpenURLIntent needs iOS 18; foreground URL routing also works on iOS 17.2.
        guard let url = URL(string: "quran://continue-reading"), await UIApplication.shared.open(url) else {
            throw ContinueReadingError.cannotOpenReader
        }
        return .result()
    }
}

@available(iOS 17.2, *)
private enum ContinueReadingError: Error, CustomLocalizedStringResourceConvertible {
    case cannotOpenReader

    var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource("The reading position could not be opened. Please open the app and try again.", table: "AppIntents")
    }
}
