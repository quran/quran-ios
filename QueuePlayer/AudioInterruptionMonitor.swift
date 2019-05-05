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

protocol AudioInterruptionMonitorDelegate: class {
    func onAudioInterruption(type: AudioInterruptionType)
}

class AudioInterruptionMonitor {
    weak var delegate: AudioInterruptionMonitorDelegate?

    init() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(onInterruption(_:)),
                           name: AVAudioSession.interruptionNotification,
                           object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func onInterruption(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }
        guard let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return
        }
        guard let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }
        switch type {
        case .began: delegate?.onAudioInterruption(type: .began)
        case .ended:
            guard let rawOptions = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume) {
                delegate?.onAudioInterruption(type: .endedShouldResume)
            } else {
                delegate?.onAudioInterruption(type: .endedShouldNotResume)
            }
        }
    }
}
