//
//  RemoteCommandsHandler.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MediaPlayer

@MainActor
struct RemoteCommandActions {
    var play: () -> Void
    var pause: () -> Void
    var togglePlayPause: () -> Void
    var nextTrack: () -> Void
    var previousTrack: () -> Void
}

@MainActor
final class RemoteCommandsHandler {
    // MARK: Lifecycle

    init(center: MPRemoteCommandCenter, actions: RemoteCommandActions) {
        self.center = center
        self.actions = actions
        setUpRemoteControlEvents()
    }

    deinit {
        Task { [center] in
            await center.setCommandsEnabled(false)
        }
    }

    // MARK: Internal

    func startListening() {
        center.setCommandsEnabled(true)
    }

    func stopListening() {
        center.setCommandsEnabled(false)
    }

    func startListeningToPlayCommand() {
        center.playCommand.isEnabled = true
    }

    // MARK: Private

    private let center: MPRemoteCommandCenter
    private let actions: RemoteCommandActions

    private func setUpRemoteControlEvents() {
        center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.actions.play()
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.actions.pause()
            }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.actions.togglePlayPause()
            }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.actions.nextTrack()
            }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.actions.previousTrack()
            }
            return .success
        }

        // disable all of them initially
        center.setCommandsEnabled(false)

        // disabled unused commands
        let unusedCommands = [
            center.seekForwardCommand,
            center.seekBackwardCommand,
            center.skipForwardCommand,
            center.skipBackwardCommand,
            center.ratingCommand,
            center.changePlaybackRateCommand,
            center.likeCommand,
            center.dislikeCommand,
            center.bookmarkCommand,
            center.changePlaybackPositionCommand,
        ]
        for command in unusedCommands {
            command.isEnabled = false
        }
    }
}

extension MPRemoteCommandCenter {
    @MainActor
    func setCommandsEnabled(_ enabled: Bool) {
        let commands = [
            playCommand,
            pauseCommand,
            togglePlayPauseCommand,
            nextTrackCommand,
            previousTrackCommand,
        ]
        for command in commands {
            command.isEnabled = enabled
        }
    }
}
