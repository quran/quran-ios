//
//  Timer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

open class Timer {

    open fileprivate(set) var isCancelled = false

    fileprivate let repeated: Bool

    fileprivate let timer: DispatchSourceTimer

    init(interval: TimeInterval,
         repeated: Bool = false,
         startNow: Bool = false,
         queue: DispatchQueue = DispatchQueue.main,
         handler: @escaping () -> Void) {
        self.repeated = repeated

        timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue)
        let dispatchInterval = UInt64(interval * Double(NSEC_PER_SEC))
        let startTime = DispatchTime.now() + Double(startNow ? 0 : Int64(dispatchInterval)) / Double(NSEC_PER_SEC)
        timer.scheduleRepeating(deadline: startTime, interval: DispatchTimeInterval.seconds(Int(interval)))

        timer.setEventHandler { [weak self] in
            if self?.isCancelled == false {
                handler()
            }

            // cancel next ones if not repeated
            if !repeated {
                self?.cancel()
            }
        }
        timer.resume()
    }

    func cancel() {
        isCancelled = true
        timer.cancel()
    }

    deinit {
        cancel()
    }
}
