//
//  AyahMenuUI.swift
//
//
//  Created by Afifi, Mohamed on 7/25/21.
//

import Combine
import SwiftUI
import UIKit

public enum AyahMenuUI {
    public struct Actions {
        // MARK: Lifecycle

        public init(
            play: @escaping () -> Void,
            repeatVerses: @escaping () -> Void,
            highlight: @escaping (NoteColor) -> Void,
            addNote: @escaping () -> Void,
            deleteNote: @escaping () -> Void,
            showTranslation: @escaping () -> Void,
            copy: @escaping () -> Void,
            share: @escaping () -> Void
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

        let play: () -> Void
        let repeatVerses: () -> Void
        let highlight: (NoteColor) -> Void
        let addNote: () -> Void
        let deleteNote: () -> Void
        let showTranslation: () -> Void
        let copy: () -> Void
        let share: () -> Void
    }

    public struct DataObject {
        // MARK: Lifecycle

        public init(
            highlightingColor: NoteColor,
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

        let highlightingColor: NoteColor
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
