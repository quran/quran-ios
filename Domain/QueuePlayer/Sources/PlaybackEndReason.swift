public enum PlaybackEndReason: Equatable, Sendable {
    case completed
    case stopped
}

enum PlaybackError: Error {
    case unavailable
    case failed
    case readinessTimedOut
}
