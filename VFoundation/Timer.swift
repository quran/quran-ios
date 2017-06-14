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

open class Timer {

    open var isCancelled: Bool {
        return cancelled.value
    }

    private let repeated: Bool

    private let timer: DispatchSourceTimer

    private var cancelled = Protected(false)

    public init(interval: TimeInterval,
                repeated: Bool = false,
                startNow: Bool = false,
                queue: DispatchQueue = .main,
                handler: @escaping () -> Void) {
        self.repeated = repeated

        timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue)
        let dispatchInterval = UInt64(interval * Double(NSEC_PER_SEC))
        let startTime = DispatchTime.now() + Double(startNow ? 0 : Int64(dispatchInterval)) / Double(NSEC_PER_SEC)
        timer.scheduleRepeating(deadline: startTime, interval: DispatchTimeInterval.seconds(Int(interval)))

        timer.setEventHandler { [weak self] in
            self?.fired(handler)
        }
        timer.resume()
    }

    private func fired(_ handler: @escaping () -> Void) {
        if !cancelled.value {
            handler()
        }

        // cancel next ones if not repeated
        if !repeated {
            cancel()
        }
    }

    public func cancel() {
        cancelled.value = true
        timer.cancel()
    }

    deinit {
        cancel()
    }
}
