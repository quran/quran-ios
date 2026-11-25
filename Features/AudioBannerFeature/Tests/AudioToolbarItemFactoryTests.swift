//
//  AudioToolbarItemFactoryTests.swift
//

import Localization
import NoorUI
import UIKit
import XCTest
@testable import AudioBannerFeature

@MainActor
final class AudioToolbarItemFactoryTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        guard #available(iOS 27.1, *) else {
            throw XCTSkip("Vertical bar items need iOS 27.1.")
        }
    }

    func test_layout_followsTheSizeClasses() {
        XCTAssertEqual(AudioToolbarLayout(horizontalSizeClass: .regular, verticalSizeClass: .regular), .full)
        XCTAssertEqual(AudioToolbarLayout(horizontalSizeClass: .compact, verticalSizeClass: .regular), .transportAndMenu)
        XCTAssertEqual(AudioToolbarLayout(horizontalSizeClass: .compact, verticalSizeClass: .compact), .playPauseAndMenu)
        XCTAssertEqual(AudioToolbarLayout(horizontalSizeClass: .regular, verticalSizeClass: .compact), .playPauseAndMenu)
    }

    func test_readyToPlay_showsPlayAndOptions() throws {
        let items = try makeItems(.readyToPlay(reciter: "Mishari"), layout: .full)

        XCTAssertEqual(labels(items), [lAndroid("play"), l("audio.options")])
    }

    func test_playing_full_showsEveryControl() throws {
        let items = try makeItems(.playing(paused: false, rate: 1), layout: .full)

        XCTAssertEqual(labels(items), [
            lAndroid("stop"),
            l("audio.playback-speed"),
            l("translation.verse.previous"),
            lAndroid("pause"),
            l("translation.verse.next"),
            l("audio.options"),
        ])
    }

    func test_playing_playPauseAndMenu_movesTheRestIntoTheMenu() throws {
        let items = try makeItems(.playing(paused: false, rate: 1.5), layout: .playPauseAndMenu)

        XCTAssertEqual(labels(items), [lAndroid("pause"), l("audio.playback.title")])
        let menu = try XCTUnwrap(items.last?.menu)
        XCTAssertEqual(titles(of: menu), [
            l("translation.verse.previous"),
            l("translation.verse.next"),
            lAndroid("stop"),
            l("audio.playback-speed"),
            l("audio.reciter"),
            l("audio.options"),
        ])
    }

    func test_pausing_updatesThePlayPauseItemInPlace() throws {
        guard #available(iOS 27.1, *) else { return }
        let item = playPauseItem

        AudioToolbarItemFactory.update(playPauseItem: item, paused: true)

        XCTAssertEqual(item.accessibilityLabel, lAndroid("play"))
        XCTAssertEqual(item.image, NoorSystemImage.play.uiImage)
        XCTAssertEqual((item.menuRepresentation as? UIAction)?.title, lAndroid("play"))
        XCTAssertTrue(try makeItems(.playing(paused: true, rate: 1), layout: .full).contains { $0 === item })
    }

    func test_choosingASpeed_setsTheRate() throws {
        let items = try makeItems(.playing(paused: false, rate: 1), layout: .full)
        let rate = try XCTUnwrap(items.first { $0.accessibilityLabel == l("audio.playback-speed") })
        let speed = try XCTUnwrap(rate.menu?.children.compactMap { $0 as? UIAction }.first { $0.title == PlaybackSpeed.formatted(2) })

        speed.performWithSender(nil, target: nil)

        XCTAssertEqual(performed, [.setRate(2)])
    }

    // MARK: Private

    private var performed: [AudioToolbarAction] = []
    private lazy var playPauseItem = NavigationBarButton.secondary(image: .pause, accessibilityLabel: lAndroid("pause")) { }

    private func makeItems(_ state: AudioBannerState, layout: AudioToolbarLayout) throws -> [UIBarButtonItem] {
        guard #available(iOS 27.1, *) else {
            throw XCTSkip("Vertical bar items need iOS 27.1.")
        }
        let factory = AudioToolbarItemFactory { [weak self] in self?.performed.append($0) }
        return factory.items(
            for: state,
            options: AudioOptionsSummary(),
            layout: layout,
            playPauseItem: playPauseItem,
            progressItem: UIBarButtonItem()
        )
    }

    /// Skips the spaces between groups.
    private func labels(_ items: [UIBarButtonItem]) -> [String] {
        items.compactMap(\.accessibilityLabel)
    }

    private func titles(of menu: UIMenu) -> [String] {
        menu.children.flatMap { element -> [String] in
            if let menu = element as? UIMenu, menu.options.contains(.displayInline) {
                return titles(of: menu)
            }
            return [element.title]
        }
    }
}
