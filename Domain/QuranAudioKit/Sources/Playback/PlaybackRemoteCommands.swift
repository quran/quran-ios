import MediaPlayer

@MainActor
final class PlaybackRemoteCommands {
    init(service: QuranPlaybackService, center: MPRemoteCommandCenter = .shared()) {
        self.center = center
        register(center.playCommand) { [weak service] in service?.handleRemotePlay() }
        register(center.pauseCommand) { [weak service] in service?.pause() }
        register(center.togglePlayPauseCommand) { [weak service] in
            if service?.state == .playing { service?.pause() } else { service?.resume() }
        }
        register(center.nextTrackCommand) { [weak service] in service?.stepForward() }
        register(center.previousTrackCommand) { [weak service] in service?.stepBackward() }
        setEnabled(false)
    }

    deinit {
        for (command, token) in targets {
            command.removeTarget(token)
        }
    }

    func setEnabled(_ enabled: Bool) {
        for (command, _) in targets {
            command.isEnabled = enabled
        }
    }

    func enableIdlePlay() {
        center.playCommand.isEnabled = true
    }

    private let center: MPRemoteCommandCenter
    private var targets: [(MPRemoteCommand, Any)] = []

    private func register(_ command: MPRemoteCommand, action: @escaping @MainActor () -> Void) {
        let token = command.addTarget { _ in
            Task { @MainActor in action() }
            return .success
        }
        targets.append((command, token))
    }
}
