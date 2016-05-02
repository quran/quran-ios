//
//  Timer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

public class Timer {

    public private(set) var isCancelled = false

    private let repeated: Bool

    private let timer: dispatch_source_t

    init(interval: NSTimeInterval,
         repeated: Bool = false,
         startNow: Bool = false,
         queue: dispatch_queue_t = dispatch_get_main_queue(),
         handler: dispatch_block_t) {
        self.repeated = repeated

        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        let dispatchInterval = UInt64(interval * Double(NSEC_PER_SEC))
        let startTime = dispatch_time(DISPATCH_TIME_NOW, startNow ? 0 : Int64(dispatchInterval))
        dispatch_source_set_timer(timer, startTime, dispatchInterval, 0)

        dispatch_source_set_event_handler(timer) { [weak self] in
            if self?.isCancelled == false {
                handler()
            }

            // cancel next ones if not repeated
            if !repeated {
                self?.cancel()
            }
        }
        dispatch_resume(timer)
    }

    func cancel() {
        isCancelled = true
        dispatch_source_cancel(timer)
    }

    deinit {
        cancel()
    }
}
