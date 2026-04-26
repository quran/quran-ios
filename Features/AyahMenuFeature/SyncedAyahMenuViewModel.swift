#if QURAN_SYNC
    import Crashing
    import FeaturesSupport
    import Localization
    import MobileSync
    import MobileSyncSupport
    import QuranAnnotations
    import QuranAudioKit
    import QuranKit
    import QuranTextKit
    import ReadingService
    import UIKit
    import VLogging

    @MainActor
    public protocol SyncedAyahMenuListener: AyahMenuListener {
        func deleteSyncHighlights(_ verses: [AyahNumber]) async
    }

    @MainActor
    final class SyncedAyahMenuViewModel {
        struct Deps {
            let sourceView: UIView
            let pointInView: CGPoint
            let verses: [AyahNumber]
            let notes: [QuranAnnotations.Note]
            let syncHighlightColor: HighlightColor?
            let hasSyncHighlight: Bool
            let syncService: SyncService?
            let bookmarkCollectionService: BookmarkCollectionService?
            let textRetriever: ShareableVerseTextRetriever
            let quranContentStatePreferences = QuranContentStatePreferences.shared
        }

        // MARK: Lifecycle

        init(deps: Deps) {
            self.deps = deps
        }

        // MARK: Internal

        weak var listener: SyncedAyahMenuListener?

        var isTranslationView: Bool {
            deps.quranContentStatePreferences.quranMode == .translation
        }

        var highlightingColor: HighlightColor {
            deps.syncHighlightColor ?? .red
        }

        var playSubtitle: String {
            if deps.verses.count > 1 {
                return l("ayah.menu.selected-verses")
            }
            switch audioPreferences.audioEnd {
            case .juz: return l("ayah.menu.play-end-juz")
            case .sura: return l("ayah.menu.play-end-surah")
            case .page: return l("ayah.menu.play-end-page")
            case .quran: return l("ayah.menu.play-end-quran")
            }
        }

        var repeatSubtitle: String {
            if deps.verses.count == 1 {
                return l("ayah.menu.selected-verse")
            }
            return l("ayah.menu.selected-verses")
        }

        var hasHighlight: Bool {
            deps.hasSyncHighlight
        }

        var hasNoteText: Bool {
            deps.notes.contains { !(($0.note ?? "").isEmpty) }
        }

        var canDeleteHighlight: Bool {
            hasHighlight
        }

        var canDeleteNote: Bool {
            hasNoteText
        }

        func play() {
            logger.info("AyahMenu: play tapped. Verses: \(deps.verses)")
            listener?.dismissAyahMenu()

            let verses = deps.verses
            let lastVerse = verses.count == 1 ? nil : verses.last
            listener?.playAudio(verses[0], to: lastVerse, repeatVerses: false)
        }

        func repeatVerses() {
            logger.info("AyahMenu: repeat verses tapped. Verses: \(deps.verses)")
            listener?.dismissAyahMenu()

            let verses = deps.verses
            listener?.playAudio(verses[0], to: verses.last, repeatVerses: true)
        }

        func deleteHighlight() async {
            logger.info("AyahMenu: delete highlight. Verses: \(deps.verses)")
            listener?.dismissAyahMenu()
            await listener?.deleteSyncHighlights(deps.verses)
        }

        func deleteNote() async {
            logger.info("AyahMenu: delete note. Verses: \(deps.verses)")
            listener?.dismissAyahMenu()
            await listener?.deleteNotes(deps.notes, verses: deps.verses)
        }

        func editNote() async {
            logger.info("AyahMenu: edit notes. Verses: \(deps.verses)")
            if let note = deps.notes.first(where: { !(($0.note ?? "").isEmpty) }) {
                listener?.editNote(note)
            } else {
                listener?.editNote(newLocalNoteDraft())
            }
        }

        func updateHighlight(color: HighlightColor) async {
            logger.info("AyahMenu: update verse highlights. Verses: \(deps.verses)")
            listener?.dismissAyahMenu()

            guard let syncService = deps.syncService, let bookmarkCollectionService = deps.bookmarkCollectionService else {
                return
            }

            do {
                try await HighlightCollection.setHighlight(
                    verses: deps.verses,
                    color: color,
                    syncService: syncService,
                    bookmarkCollectionService: bookmarkCollectionService
                )
            } catch {
                crasher.recordError(error, reason: "Failed to update synced highlights")
            }
        }

        func showTranslation() {
            logger.info("AyahMenu: showTranslation. Verses: \(deps.verses)")
            listener?.showTranslation(deps.verses)
        }

        func copy() {
            logger.info("AyahMenu: copy. Verses: \(deps.verses)")
            listener?.dismissAyahMenu()
            Task {
                if let lines = try? await retrieveSelectedAyahText() {
                    UIPasteboard.general.string = lines.joined(separator: "\n")
                }
            }
        }

        func share() {
            logger.info("AyahMenu: share. Verses: \(deps.verses)")
            Task {
                if let lines = try? await retrieveSelectedAyahText() {
                    listener?.shareText([lines.joined(separator: "\n")], in: deps.sourceView, at: deps.pointInView)
                }
            }
        }

        // MARK: Private

        private let audioPreferences = AudioPreferences.shared
        private let deps: Deps

        private func newLocalNoteDraft() -> QuranAnnotations.Note {
            QuranAnnotations.Note(
                verses: Set(deps.verses),
                modifiedDate: Date(),
                note: nil,
                color: noteColor(from: highlightingColor)
            )
        }

        private func noteColor(from color: HighlightColor) -> QuranAnnotations.Note.Color {
            switch color {
            case .red: .red
            case .green: .green
            case .blue: .blue
            case .yellow: .yellow
            case .purple: .purple
            }
        }

        private func retrieveSelectedAyahText() async throws -> [String] {
            try await crasher.recordError("Failed to update highlights") {
                try await deps.textRetriever.textForVerses(deps.verses)
            }
        }
    }
#endif
