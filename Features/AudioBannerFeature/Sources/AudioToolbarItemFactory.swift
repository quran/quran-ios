//
//  AudioToolbarItemFactory.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import Localization
import NoorUI
import UIKit

/// What an audio bar item asks the audio banner to do.
enum AudioToolbarAction: Equatable {
    case play
    case pause
    case resume
    case stop
    case backward
    case forward
    case cancelDownload
    case showReciters
    case showOptions
    case setRate(Float)
}

/// Makes the bar items for an audio banner state. Icon-only items get a VoiceOver label and a titled entry for the
/// menu that collects items when the bar runs out of room.
@available(iOS 27.1, *)
@MainActor
struct AudioToolbarItemFactory {
    // MARK: Internal

    let perform: @MainActor @Sendable (AudioToolbarAction) -> Void

    /// Shows pause or resume on an item that stays in the bar, so VoiceOver keeps its focus when it's tapped.
    static func update(playPauseItem item: UIBarButtonItem, paused: Bool) {
        item.image = (paused ? NoorSystemImage.play : .pause).uiImage
        item.accessibilityLabel = paused ? lAndroid("play") : lAndroid("pause")
    }

    /// - Parameters:
    ///   - playPauseItem: Kept across play and pause; see `update(playPauseItem:paused:)`.
    ///   - progressItem: Kept across progress updates, so the ring doesn't flicker.
    func items(
        for state: AudioBannerState,
        options: AudioOptionsSummary,
        layout: AudioToolbarLayout,
        playPauseItem: UIBarButtonItem,
        progressItem: @autoclosure () -> UIBarButtonItem
    ) -> [UIBarButtonItem] {
        // Each group shares one capsule.
        let groups: [[UIBarButtonItem]] = switch state {
        case .readyToPlay:
            [[button(.play, lAndroid("play"), .play, highPriority: true)], [optionsItem(options)]]
        case .playing(_, let rate):
            switch layout {
            case .full:
                [
                    [button(.stop, lAndroid("stop"), .stop)],
                    [rateItem(rate)],
                    transportItems(playPauseItem),
                    [optionsItem(options)],
                ]
            case .transportAndMenu:
                [transportItems(playPauseItem), [audioMenuItem(rate: rate, options: options, includesSkipping: false)]]
            case .playPauseAndMenu:
                [[playPauseItem], [audioMenuItem(rate: rate, options: options, includesSkipping: true)]]
            }
        case .downloading:
            [[progressItem()]]
        }
        for item in groups.joined() {
            item.axisBehavior = .verticalPreferred
        }
        return Array(groups.joined(separator: [UIBarButtonItem.fixedSpace()]))
    }

    // MARK: Private

    private func transportItems(_ playPauseItem: UIBarButtonItem) -> [UIBarButtonItem] {
        [
            button(.backward, l("translation.verse.previous"), .backward, highPriority: true),
            playPauseItem,
            button(.forward, l("translation.verse.next"), .forward, highPriority: true),
        ]
    }

    private func button(
        _ image: NoorSystemImage,
        _ title: String,
        _ action: AudioToolbarAction,
        highPriority: Bool = false
    ) -> UIBarButtonItem {
        let perform = perform
        let item = NavigationBarButton.secondary(image: image, accessibilityLabel: title) { perform(action) }
        if highPriority {
            item.visibilityPriority = .high
        }
        return item
    }

    private func optionsItem(_ options: AudioOptionsSummary) -> UIBarButtonItem {
        let item = button(.audioOptions, l("audio.options"), .showOptions)
        decorate(item, options: options)
        return item
    }

    private func rateItem(_ rate: Float) -> UIBarButtonItem {
        let item = UIBarButtonItem(title: PlaybackSpeed.formatted(rate), menu: rateMenu(rate, inline: true))
        item.tintColor = .label
        item.accessibilityLabel = l("audio.playback-speed")
        item.menuRepresentation = rateMenu(rate, inline: false)
        return item
    }

    private func rateMenu(_ rate: Float, inline: Bool) -> UIMenu {
        let perform = perform
        let actions = PlaybackSpeed.supportedRates.map { value in
            UIAction(title: PlaybackSpeed.formatted(value), state: value == rate ? .on : .off) { _ in
                perform(.setRate(value))
            }
        }
        if inline {
            return UIMenu(children: actions)
        }
        let menu = UIMenu(title: l("audio.playback-speed"), image: NoorSystemImage.playbackSpeed.uiImage, children: actions)
        menu.subtitle = PlaybackSpeed.formatted(rate)
        return menu
    }

    /// The short bar's one audio button, which takes what doesn't fit.
    private func audioMenuItem(rate: Float, options: AudioOptionsSummary, includesSkipping: Bool) -> UIBarButtonItem {
        let skipping: [UIMenuElement] = includesSkipping
            ? [UIMenu(options: .displayInline, children: [
                action(.backward, l("translation.verse.previous"), .backward),
                action(.forward, l("translation.verse.next"), .forward),
            ])]
            : []
        let optionsAction = action(.audioOptions, l("audio.options"), .showOptions)
        optionsAction.subtitle = options.hasNonDefaultValues ? options.text : nil
        let children = skipping + [
            UIMenu(options: .displayInline, children: [action(.stop, lAndroid("stop"), .stop)]),
            rateMenu(rate, inline: false),
            UIMenu(options: .displayInline, children: [action(.reciter, l("audio.reciter"), .showReciters), optionsAction]),
        ]
        let title = l("audio.playback.title")
        let item = UIBarButtonItem(image: NoorSystemImage.audio.uiImage, menu: UIMenu(children: children))
        item.tintColor = .label
        item.accessibilityLabel = title
        item.menuRepresentation = UIMenu(title: title, image: NoorSystemImage.audio.uiImage, children: children)
        decorate(item, options: options)
        return item
    }

    private func action(_ image: NoorSystemImage, _ title: String, _ action: AudioToolbarAction) -> UIAction {
        let perform = perform
        return UIAction(title: title, image: image.uiImage) { _ in perform(action) }
    }

    private func decorate(_ item: UIBarButtonItem, options: AudioOptionsSummary) {
        item.accessibilityValue = options.hasNonDefaultValues ? options.text : nil
        item.badge = options.hasNonDefaultValues ? .indicator() : nil
    }
}
