//
//  AyahMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

public struct AyahMenuInput {
    // MARK: Lifecycle

    public init(
        sourceView: UIView,
        pointInView: CGPoint,
        verses: [AyahNumber],
        notes: [QuranAnnotations.Note]
    ) {
        self.sourceView = sourceView
        self.pointInView = pointInView
        self.verses = verses
        self.notes = notes
    }

    // MARK: Internal

    let sourceView: UIView
    let pointInView: CGPoint
    let verses: [AyahNumber]
    let notes: [QuranAnnotations.Note]
}

@MainActor
public struct AyahMenuBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: AyahMenuListener, input: AyahMenuInput) -> UIViewController {
        let textRetriever = ShareableVerseTextRetriever(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        #if QURAN_SYNC
        let deps = AyahMenuViewModel.Deps(
            sourceView: input.sourceView,
            pointInView: input.pointInView,
            verses: input.verses,
            textRetriever: textRetriever,
            notes: input.notes
        )
        #else
        let deps = AyahMenuViewModel.Deps(
            sourceView: input.sourceView,
            pointInView: input.pointInView,
            verses: input.verses,
            textRetriever: textRetriever,
            notes: input.notes,
            noteService: container.noteService()
        )
        #endif
        let viewModel = AyahMenuViewModel(deps: deps)
        viewModel.listener = listener
        return AyahMenuViewController(viewModel: viewModel)
    }

    // MARK: Private

    private let container: AppDependencies
}
