//
//  AudioToolbarItems.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import Combine
import Localization
import NoorUI
import UIKit

/// The audio banner's controls as bar items, for bars that show them instead of the banner, like the reader's
/// controls in iPhone Duo's vertical bar.
@MainActor
public final class AudioToolbarItems {
    // MARK: Lifecycle

    init(viewModel: AudioBannerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Public

    public private(set) var items: [UIBarButtonItem] = []

    /// Called after `items` changes.
    public var onItemsChange: (() -> Void)?

    /// The traits of the vertical bar showing the items, or `nil` while none does. The items follow the banner only
    /// while it's set, so nothing runs elsewhere.
    public var barTraits: UITraitCollection? {
        didSet {
            let layout = barTraits.map {
                AudioToolbarLayout(horizontalSizeClass: $0.horizontalSizeClass, verticalSizeClass: $0.verticalSizeClass)
            }
            guard layout != self.layout else {
                return
            }
            self.layout = layout
            observeViewModel()
            update()
        }
    }

    // MARK: Private

    /// What the items show; play and pause only update the play/pause item.
    private struct Content: Equatable {
        enum State: Equatable {
            case readyToPlay
            case playing(rate: Float)
            case downloading
        }

        let state: State
        let options: AudioOptionsSummary
        let layout: AudioToolbarLayout
    }

    private let viewModel: AudioBannerViewModel
    private var layout: AudioToolbarLayout?
    private var cancellable: AnyCancellable?
    private var content: Content?
    private var paused = false
    private var progressButton: UIButton?

    private lazy var playPauseItem = NavigationBarButton.secondary(image: .pause, accessibilityLabel: lAndroid("pause")) {
        [weak self] in
        guard let self else { return }
        perform(paused ? .resume : .pause)
    }

    private func observeViewModel() {
        guard layout != nil else {
            cancellable = nil
            return
        }
        guard cancellable == nil else {
            return
        }
        cancellable = viewModel.objectWillChange
            // objectWillChange fires before the change, so read the state on the next turn.
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.update() }
    }

    private func update() {
        guard #available(iOS 27.1, *), let layout else {
            content = nil
            setItems([])
            return
        }
        let state = viewModel.audioBannerState
        let options = viewModel.audioOptionsSummary
        let contentState: Content.State
        switch state {
        case .readyToPlay:
            contentState = .readyToPlay
        case .playing(let paused, let rate):
            contentState = .playing(rate: rate)
            self.paused = paused
            AudioToolbarItemFactory.update(playPauseItem: playPauseItem, paused: paused)
        case .downloading(let progress):
            contentState = .downloading
            downloadProgressButton.progress = progress
        }
        let content = Content(state: contentState, options: options, layout: layout)
        guard content != self.content else {
            return
        }
        self.content = content
        let factory = AudioToolbarItemFactory { [weak self] in self?.perform($0) }
        setItems(factory.items(
            for: state,
            options: options,
            layout: layout,
            playPauseItem: playPauseItem,
            progressItem: makeProgressItem()
        ))
    }

    private func setItems(_ items: [UIBarButtonItem]) {
        guard !(items.isEmpty && self.items.isEmpty) else {
            return
        }
        self.items = items
        onItemsChange?()
    }

    @available(iOS 17.0, *)
    private var downloadProgressButton: CircularDownloadProgressButton {
        if let button = progressButton as? CircularDownloadProgressButton {
            return button
        }
        let button = CircularDownloadProgressButton(cancel: UIAction { [weak self] _ in
            self?.perform(.cancelDownload)
        })
        progressButton = button
        return button
    }

    @available(iOS 17.0, *)
    private func makeProgressItem() -> UIBarButtonItem {
        // The ring shows in a bar only as a custom view, which carries its own VoiceOver label.
        let item = UIBarButtonItem(customView: downloadProgressButton)
        item.menuRepresentation = UIAction(title: lAndroid("cancel"), image: NoorSystemImage.cancel.uiImage) { [weak self] _ in
            self?.perform(.cancelDownload)
        }
        return item
    }

    private func perform(_ action: AudioToolbarAction) {
        switch action {
        case .play: viewModel.playFromBanner()
        case .pause: viewModel.pauseFromBanner()
        case .resume: viewModel.resumeFromBanner()
        case .stop: viewModel.stopFromBanner()
        case .backward: viewModel.backwardFromBanner()
        case .forward: viewModel.forwardFromBanner()
        case .cancelDownload: Task { await viewModel.cancelDownload() }
        case .showReciters: viewModel.presentReciterList()
        case .showOptions: viewModel.showAdvancedAudioOptions()
        case .setRate(let rate): viewModel.updatePlaybackRate(to: rate)
        }
    }
}
