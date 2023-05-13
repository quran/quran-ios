//
//  AudioInterruptionMonitor.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/29/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation

enum AudioInterruptionType {
    case began
    case endedShouldResume
    case endedShouldNotResume
}

final class AudioInterruptionMonitor {
    @MainActor var onAudioInterruption: (@MainActor (AudioInterruptionType) -> Void)?

    init() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(onInterruption(_:)),
                           name: AVAudioSession.interruptionNotification,
                           object: nil)
    }

    @objc
    private func onInterruption(_ notification: Notification) {
        if let type = Self.extractInterruptionType(from: notification) {
            Task {
                await onAudioInterruption?(type)
            }
        }
    }

    private static func extractInterruptionType(from notification: Notification) -> AudioInterruptionType? {
        guard let info = notification.userInfo else {
            return nil
        }
        guard let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return nil
        }
        guard let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return nil
        }
        switch type {
        case .began:
            return .began
        case .ended:
            guard let rawOptions = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return nil
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume) {
                return .endedShouldResume
            } else {
                return .endedShouldNotResume
            }
        @unknown default:
            assertionFailure("Unimplemented case")
            return nil
        }
    }
}
