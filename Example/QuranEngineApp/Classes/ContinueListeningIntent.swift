import AppIntents
import Foundation

@available(iOS 17.2, *)
struct ContinueListeningIntent: AudioPlaybackIntent {
    static let title = LocalizedStringResource("Continue Listening", table: "AppIntents")
    static let description = IntentDescription(
        LocalizedStringResource("Resume Quran recitation from your listening position for the selected number of pages.", table: "AppIntents")
    )

    // Keep iOS 17.2–25 background execution while using the current runtime API on iOS 26+.
    static let openAppWhenRun = false

    @available(iOS 26.0, *)
    static let supportedModes: IntentModes = .background

    @Parameter(title: LocalizedStringResource("Amount", table: "AppIntents"), default: .five)
    var amount: ListeningPageAmount

    @MainActor
    func perform() async throws -> some IntentResult {
        try await Container.shared.continueListening(pageCount: amount.pageCount)
        return .result()
    }
}

/// Supports any positive count in Shortcuts, or a Siri follow-up question, without an open-ended phrase slot.
@available(iOS 17.2, *)
struct ContinueListeningToPagesIntent: AudioPlaybackIntent {
    static let title = LocalizedStringResource("Continue Listening to Pages", table: "AppIntents")
    static let description = IntentDescription(
        LocalizedStringResource("Choose how many Quran pages to hear from your saved listening position. Playback stops at the end of the Quran if fewer pages remain.", table: "AppIntents")
    )

    static let openAppWhenRun = false

    @available(iOS 26.0, *)
    static let supportedModes: IntentModes = .background

    @Parameter(title: LocalizedStringResource("Number of Pages", table: "AppIntents"))
    var pageCount: Int?

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let pageCount else {
            throw $pageCount.needsValueError(IntentDialog(
                LocalizedStringResource("How many pages would you like to hear?", table: "AppIntents")
            ))
        }
        guard pageCount > 0 else {
            throw $pageCount.needsValueError(IntentDialog(
                LocalizedStringResource("Choose at least one page. How many pages would you like to hear?", table: "AppIntents")
            ))
        }
        try await Container.shared.continueListening(pageCount: pageCount)
        return .result()
    }
}
