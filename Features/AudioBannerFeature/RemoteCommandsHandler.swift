//
//  RemoteCommandsHandler.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MediaPlayer

@MainActor
protocol RemoteCommandsHandlerDelegate: AnyObject {
    func onPlayCommandFired()
    func onPauseCommandFired()
    func onTogglePlayPauseCommandFired()
    func onStepForwardCommandFired()
    func onStepBackwardCommandFire()
}

final class RemoteCommandsHandler: Sendable {
    // MARK: Lifecycle

    init(center: MPRemoteCommandCenter) {
        self.center = center
        setUpRemoteControlEvents()
    }

    deinit {
        stopListening()
    }

    // MARK: Internal

    weak var delegate: RemoteCommandsHandlerDelegate?

    func startListening() {
        setCommandsEnabled(true)
    }

    func stopListening() {
        setCommandsEnabled(false)
    }

    func startListeningToPlayCommand() {
        center.playCommand.isEnabled = true
    }

    // MARK: Private

    private let center: MPRemoteCommandCenter

    private func setUpRemoteControlEvents() {
        center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.delegate?.onPlayCommandFired()
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.delegate?.onPauseCommandFired()
            }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.delegate?.onTogglePlayPauseCommandFired()
            }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.delegate?.onStepForwardCommandFired()
            }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .success }
            Task { @MainActor in
                self.delegate?.onStepBackwardCommandFire()
            }
            return .success
        }

        // disable all of them initially
        setCommandsEnabled(false)

        // disabled unused command
        [center.seekForwardCommand, center.seekBackwardCommand, center.skipForwardCommand,
         center.skipBackwardCommand, center.ratingCommand, center.changePlaybackRateCommand,
         center.likeCommand, center.dislikeCommand, center.bookmarkCommand, center.changePlaybackPositionCommand].forEach { $0.isEnabled = false }
    }

    private func setCommandsEnabled(_ enabled: Bool) {
        let center = MPRemoteCommandCenter.shared()
        [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
         center.nextTrackCommand, center.previousTrackCommand].forEach { $0.isEnabled = enabled }
    }
}
