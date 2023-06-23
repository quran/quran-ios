//
//  AyahMenuViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import NoorUI
import QuranAnnotations
import SwiftUI
import UIx

final class AyahMenuViewController: UIViewController {
    // MARK: Lifecycle

    init(viewModel: AyahMenuViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        let actions = AyahMenuUI.Actions(
            play: { [weak self] in self?.viewModel.play() },
            repeatVerses: { [weak self] in self?.viewModel.repeatVerses() },
            highlight: { [weak self] color in await self?.viewModel.updateHighlight(color: color) },
            addNote: { [weak self] in await self?.viewModel.editNote() },
            deleteNote: { [weak self] in await self?.viewModel.deleteNotes() },
            showTranslation: { [weak self] in self?.viewModel.showTranslation() },
            copy: { [weak self] in self?.viewModel.copy() },
            share: { [weak self] in self?.viewModel.share() }
        )
        let highlightingColor = viewModel.highlightingColor
        let dataObject = AyahMenuUI.DataObject(
            highlightingColor: highlightingColor,
            state: viewModel.noteState,
            playSubtitle: viewModel.playSubtitle,
            repeatSubtitle: viewModel.repeatSubtitle,
            actions: actions,
            isTranslationView: viewModel.isTranslationView
        )
        showAyahMenu(dataObject)
    }

    // MARK: Private

    private let viewModel: AyahMenuViewModel

    private func showAyahMenu(_ dataObject: AyahMenuUI.DataObject) {
        let view = AyahMenuView(dataObject: dataObject)
        let hostingController = AutoUpdatingPreferredContentSizeHostingController(rootView: view)
        addFullScreenChild(hostingController)
    }
}
