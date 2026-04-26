import QuranAnnotations
import UIx

public enum SyncedAyahMenuUI {
    public struct Actions {
        // MARK: Lifecycle

        public init(
            play: @escaping AsyncAction,
            repeatVerses: @escaping AsyncAction,
            highlight: @Sendable @escaping (HighlightColor) async -> Void,
            addNote: @escaping AsyncAction,
            deleteHighlight: AsyncAction? = nil,
            deleteNote: AsyncAction? = nil,
            showTranslation: @escaping AsyncAction,
            copy: @escaping AsyncAction,
            share: @escaping AsyncAction
        ) {
            self.play = play
            self.repeatVerses = repeatVerses
            self.highlight = highlight
            self.addNote = addNote
            self.deleteHighlight = deleteHighlight
            self.deleteNote = deleteNote
            self.showTranslation = showTranslation
            self.copy = copy
            self.share = share
        }

        // MARK: Internal

        let play: AsyncAction
        let repeatVerses: AsyncAction
        let highlight: @Sendable (HighlightColor) async -> Void
        let addNote: AsyncAction
        let deleteHighlight: AsyncAction?
        let deleteNote: AsyncAction?
        let showTranslation: AsyncAction
        let copy: AsyncAction
        let share: AsyncAction
    }

    public struct DataObject {
        // MARK: Lifecycle

        public init(
            highlightingColor: HighlightColor,
            hasHighlight: Bool,
            hasNoteText: Bool,
            playSubtitle: String,
            repeatSubtitle: String,
            actions: Actions,
            isTranslationView: Bool
        ) {
            self.highlightingColor = highlightingColor
            self.hasHighlight = hasHighlight
            self.hasNoteText = hasNoteText
            self.playSubtitle = playSubtitle
            self.repeatSubtitle = repeatSubtitle
            self.actions = actions
            self.isTranslationView = isTranslationView
        }

        // MARK: Internal

        let highlightingColor: HighlightColor
        let hasHighlight: Bool
        let hasNoteText: Bool
        let actions: Actions
        let playSubtitle: String
        let repeatSubtitle: String
        let isTranslationView: Bool
    }
}
