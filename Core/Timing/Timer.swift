//
//  Timer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import Locking

open class Timer {
    // MARK: Lifecycle

    public init(
        interval: TimeInterval,
        repeated: Bool = false,
        startNow: Bool = false,
        queue: DispatchQueue = .main,
        handler: @escaping () -> Void
    ) {
        self.repeated = repeated

        timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue)
        let dispatchInterval = UInt64(interval * Double(NSEC_PER_SEC))
        let startTime = DispatchTime.now() + Double(startNow ? 0 : Int64(dispatchInterval)) / Double(NSEC_PER_SEC)
        timer.schedule(deadline: startTime, repeating: DispatchTimeInterval.seconds(Int(interval)))

        eventHandler = handler
        timer.setEventHandler { [weak self] in
            self?.fired()
        }
        timer.resume()
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        resume()
        eventHandler = nil
    }

    // MARK: Open

    open var isCancelled: Bool {
        cancelled.value
    }

    // MARK: Public

    public func cancel() {
        cancelled.value = true
        timer.cancel()
    }

    public func pause() {
        state.sync { state in
            guard state == .resumed else {
                return
            }
            state = .paused
            timer.suspend()
        }
    }

    public func resume() {
        state.sync { state in
            guard state == .paused else {
                return
            }
            state = .resumed
            timer.resume()
        }
    }

    // MARK: Private

    // MARK: - Pause/Resume

    private enum State {
        case paused
        case resumed
    }

    private let repeated: Bool

    private let timer: DispatchSourceTimer

    private var cancelled = Protected(false)

    private var eventHandler: (() -> Void)?

    private var state = Protected(State.resumed)

    private func fired() {
        if !cancelled.value {
            eventHandler?()
        }

        // cancel next ones if not repeated
        if !repeated {
            cancel()
        }
    }
}
