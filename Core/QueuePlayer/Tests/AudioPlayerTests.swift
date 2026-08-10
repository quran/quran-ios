import AVFoundation
import XCTest
@testable import QueuePlayer

final class AudioPlayerTests: XCTestCase {
    func testPlaybackTimerIntervalRequiresKnownFiniteFrameEnd() {
        XCTAssertNil(playbackTimerInterval(frameEndTime: nil, currentTime: 0, playbackRate: 1))
        XCTAssertNil(playbackTimerInterval(frameEndTime: .nan, currentTime: 0, playbackRate: 1))
        XCTAssertNil(playbackTimerInterval(frameEndTime: 1, currentTime: .nan, playbackRate: 1))
        XCTAssertEqual(playbackTimerInterval(frameEndTime: 3, currentTime: 1, playbackRate: 2), 1)
    }

    @MainActor
    func testPlayerNotifiesWhenWholeFileReachesNaturalEnd() async {
        let player = Player(url: URL(fileURLWithPath: "/tmp/QueuePlayerTests.mp3"))
        let playbackEnded = expectation(description: "Playback ended")
        player.onPlaybackEnded = {
            playbackEnded.fulfill()
        }

        NotificationCenter.default.post(
            name: AVPlayerItem.didPlayToEndTimeNotification,
            object: player.playerItem
        )

        await fulfillment(of: [playbackEnded], timeout: 1)
    }
}
