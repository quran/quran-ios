//
//  AdvancedAudioOptionsViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-07.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Localization
import NoorUI
import QuranAudio
import QuranKit
import ReciterListFeature
import SwiftUI

class AdvancedAudioOptionsNavigationController: BaseNavigationController, ReciterListListener {
    // MARK: Lifecycle

    init(
        viewModel: AdvancedAudioOptionsInteractor,
        reciterListBuilder: ReciterListBuilder
    ) {
        self.reciterListBuilder = reciterListBuilder
        rootViewController = AdvancedAudioOptionsViewController(viewModel: viewModel)
        super.init(rootViewController: rootViewController)
        rootViewController.actions = AdvancedAudioOptionsViewController.Actions(
            presentReciterList: { [weak self] in self?.presentReciterList() },
            showFromVerseSelection: { [weak self] in self?.showFromVerseSelection() },
            showToVerseSelection: { [weak self] in self?.showToVerseSelection() }
        )
        rotateToPortraitIfPhone()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
    }

    func onSelectedReciterChanged(to reciter: Reciter) {
        rootViewController.viewModel.updateReciter(to: reciter)
    }

    func dismissReciterList() {
        popViewController(animated: true)
    }

    // MARK: Private

    private let rootViewController: AdvancedAudioOptionsViewController
    private let reciterListBuilder: ReciterListBuilder

    private func showFromVerseSelection() {
        let dataObject = rootViewController.viewModel.dataObject
        let verseSelection = AdvancedAudioVersesViewController(
            suras: dataObject.suras,
            selected: dataObject.fromVerse
        ) { [weak self] in
            self?.rootViewController.viewModel.updateFromVerseTo($0)
            self?.popViewController(animated: true)
        }
        verseSelection.title = l("audio.select-start-verse")
        pushViewController(verseSelection, animated: true)
    }

    private func showToVerseSelection() {
        let dataObject = rootViewController.viewModel.dataObject
        let verseSelection = AdvancedAudioVersesViewController(
            suras: dataObject.suras,
            selected: dataObject.toVerse
        ) { [weak self] in
            self?.rootViewController.viewModel.updateToVerseTo($0)
            self?.popViewController(animated: true)
        }
        verseSelection.title = l("audio.select-end-verse")
        pushViewController(verseSelection, animated: true)
    }

    private func presentReciterList() {
        let viewController = reciterListBuilder.build(withListener: self)
        pushViewController(viewController, animated: true)
    }
}

class AdvancedAudioOptionsViewController: BaseViewController {
    struct Actions {
        var presentReciterList: () -> Void
        var showFromVerseSelection: () -> Void
        var showToVerseSelection: () -> Void
    }

    // MARK: Lifecycle

    init(viewModel: AdvancedAudioOptionsInteractor) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var actions: Actions?

    let viewModel: AdvancedAudioOptionsInteractor

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        addAdvancedAudioView()
    }

    @objc
    func playButtonTapped() {
        viewModel.play()
    }

    @objc
    func dismissView() {
        viewModel.dismiss()
    }

    func addAdvancedAudioView() {
        let view = AdvancedAudioOptionsView(dataObject: viewModel.dataObject, actions: viewActions)
        let viewController = UIHostingController(rootView: view)
        addFullScreenChild(viewController)
    }

    // MARK: Private

    private var viewActions: AdvancedAudioUI.Actions {
        AdvancedAudioUI.Actions(
            reciterTapped: { [weak self] in self?.actions?.presentReciterList() },
            lastPageTapped: { [weak self] in self?.viewModel.setLastVerseInPage() },
            lastSuraTapped: { [weak self] in self?.viewModel.setLastVerseInSura() },
            lastJuzTapped: { [weak self] in self?.viewModel.setLastVerseInJuz() },
            fromVerseTapped: { [weak self] in self?.actions?.showFromVerseSelection() },
            toVerseTapped: { [weak self] in self?.actions?.showToVerseSelection() }
        )
    }

    private func configureNavigationBar() {
        let playImage = UIImage.symbol("play.fill")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: playImage, style: .done, target: self, action: #selector(playButtonTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
    }
}
