//
//  RemoteCommandsHandler.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MediaPlayer

protocol RemoteCommandsHandlerDelegate: class {
    func onPlayCommandFired()
    func onPauseCommandFired()
    func onTogglePlayPauseCommandFired()
    func onStepForwardCommandFired()
    func onStepBackwardCommandFire()
}

class RemoteCommandsHandler {
    weak var delegate: RemoteCommandsHandlerDelegate?

    private let center: MPRemoteCommandCenter

    init(center: MPRemoteCommandCenter) {
        self.center = center
        setUpRemoteControlEvents()
    }

    deinit {
        stopListening()
    }

    func startListening() {
        setCommandsEnabled(true)
    }

    func stopListening() {
        setCommandsEnabled(false)
    }

    func startListeningToPlayCommand() {
        center.playCommand.isEnabled = true
    }

    private func setUpRemoteControlEvents() {
        center.playCommand.addTarget (handler: { [weak self] _ in
            self?.delegate?.onPlayCommandFired()
            return .success
        })
        center.pauseCommand.addTarget (handler: { [weak self] _ in
            self?.delegate?.onPauseCommandFired()
            return .success
        })
        center.togglePlayPauseCommand.addTarget (handler: { [weak self] _ in
            self?.delegate?.onTogglePlayPauseCommandFired()
            return .success
        })
        center.nextTrackCommand.addTarget (handler: { [weak self] _ in
            self?.delegate?.onStepForwardCommandFired()
            return .success
        })
        center.previousTrackCommand.addTarget (handler: { [weak self] _ in
            self?.delegate?.onStepBackwardCommandFire()
            return .success
        })

        // disable all of them initially
        setCommandsEnabled(false)

        // disabled unused command
        if #available(iOS 9.1, *) {
            [center.seekForwardCommand, center.seekBackwardCommand, center.skipForwardCommand,
             center.skipBackwardCommand, center.ratingCommand, center.changePlaybackRateCommand,
             center.likeCommand, center.dislikeCommand, center.bookmarkCommand, center.changePlaybackPositionCommand].forEach { $0.isEnabled = false }
        }
    }

    private func setCommandsEnabled(_ enabled: Bool) {
        let center = MPRemoteCommandCenter.shared()
        [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
         center.nextTrackCommand, center.previousTrackCommand].forEach { $0.isEnabled = enabled }
    }
}
