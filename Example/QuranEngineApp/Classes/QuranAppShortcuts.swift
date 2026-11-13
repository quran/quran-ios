import AppIntents
import Foundation

@available(iOS 17.2, *)
struct QuranAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ContinueListeningIntent(),
            phrases: [
                "Continue listening in \(.applicationName)",
                "Continue listening to \(.applicationName) next \(\.$amount)",
                "Continue listening in \(.applicationName) for \(\.$amount)",
                "Listen to the next \(\.$amount) in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Continue Listening", table: "AppIntents"),
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: ContinueListeningToPagesIntent(),
            phrases: [
                "Choose how many pages to hear in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Listen to Pages", table: "AppIntents"),
            systemImageName: "headphones"
        )
        AppShortcut(
            intent: ContinueReadingIntent(),
            phrases: [
                "Continue reading in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Continue Reading", table: "AppIntents"),
            systemImageName: "book.fill"
        )
    }
}
