//
//  AyahMenuUI.swift
//
//
//  Created by Afifi, Mohamed on 7/25/21.
//

import QuranAnnotations
import UIx

public enum AyahMenuUI {
    public struct Actions {
        // MARK: Lifecycle

        public init(
            play: @escaping AsyncAction,
            repeatVerses: @escaping AsyncAction,
            bookmark: @escaping AsyncAction,
            addNote: @escaping AsyncAction,
            deleteNote: @escaping AsyncAction,
            showTranslation: @escaping AsyncAction,
            copy: @escaping AsyncAction,
            share: @escaping AsyncAction
        ) {
            self.play = play
            self.repeatVerses = repeatVerses
            self.bookmark = bookmark
            self.addNote = addNote
            self.deleteNote = deleteNote
            self.showTranslation = showTranslation
            self.copy = copy
            self.share = share
        }

        // MARK: Internal

        let play: AsyncAction
        let repeatVerses: AsyncAction
        let bookmark: AsyncAction
        let addNote: AsyncAction
        let deleteNote: AsyncAction
        let showTranslation: AsyncAction
        let copy: AsyncAction
        let share: AsyncAction
    }

    public struct DataObject {
        // MARK: Lifecycle

        public init(
            highlightingColor: HighlightColor,
            state: NoteState,
            bookmarkTitle: String,
            playSubtitle: String,
            repeatSubtitle: String,
            actions: Actions,
            isTranslationView: Bool,
            usesSyncedNotesIcon: Bool = false
        ) {
            self.highlightingColor = highlightingColor
            self.state = state
            self.bookmarkTitle = bookmarkTitle
            self.playSubtitle = playSubtitle
            self.repeatSubtitle = repeatSubtitle
            self.actions = actions
            self.isTranslationView = isTranslationView
            self.usesSyncedNotesIcon = usesSyncedNotesIcon
        }

        // MARK: Internal

        let highlightingColor: HighlightColor
        let state: NoteState
        let actions: Actions
        let bookmarkTitle: String
        let playSubtitle: String
        let repeatSubtitle: String
        let isTranslationView: Bool
        let usesSyncedNotesIcon: Bool
    }

    // MARK: Public

    public enum NoteState {
        case noHighlight
        case highlighted
        case noted
    }
}
