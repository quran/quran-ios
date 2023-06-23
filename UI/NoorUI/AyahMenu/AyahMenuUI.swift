//
//  AyahMenuUI.swift
//
//
//  Created by Afifi, Mohamed on 7/25/21.
//

import Combine
import QuranAnnotations
import SwiftUI
import UIKit
import UIx

public enum AyahMenuUI {
    public struct Actions {
        // MARK: Lifecycle

        public init(
            play: @escaping AsyncAction,
            repeatVerses: @escaping AsyncAction,
            highlight: @Sendable @escaping (Note.Color) async -> Void,
            addNote: @escaping AsyncAction,
            deleteNote: @escaping AsyncAction,
            showTranslation: @escaping AsyncAction,
            copy: @escaping AsyncAction,
            share: @escaping AsyncAction
        ) {
            self.play = play
            self.repeatVerses = repeatVerses
            self.highlight = highlight
            self.addNote = addNote
            self.deleteNote = deleteNote
            self.showTranslation = showTranslation
            self.copy = copy
            self.share = share
        }

        // MARK: Internal

        let play: AsyncAction
        let repeatVerses: AsyncAction
        let highlight: @Sendable (Note.Color) async -> Void
        let addNote: AsyncAction
        let deleteNote: AsyncAction
        let showTranslation: AsyncAction
        let copy: AsyncAction
        let share: AsyncAction
    }

    public struct DataObject {
        // MARK: Lifecycle

        public init(
            highlightingColor: Note.Color,
            state: NoteState,
            playSubtitle: String,
            repeatSubtitle: String,
            actions: Actions,
            isTranslationView: Bool
        ) {
            self.highlightingColor = highlightingColor
            self.state = state
            self.playSubtitle = playSubtitle
            self.repeatSubtitle = repeatSubtitle
            self.actions = actions
            self.isTranslationView = isTranslationView
        }

        // MARK: Internal

        let highlightingColor: Note.Color
        let state: NoteState
        let actions: Actions
        let playSubtitle: String
        let repeatSubtitle: String
        let isTranslationView: Bool
    }

    // MARK: Public

    public enum NoteState {
        case noHighlight
        case highlighted
        case noted
    }
}
