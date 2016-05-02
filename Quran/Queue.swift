//
//  Queue.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Queue {

    let queue: dispatch_queue_t

    static let main = Queue(queue: dispatch_get_main_queue())
    static let background = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

    func async(block: () -> Void) {
        dispatch_async(queue, block)
    }

    func after(timerInterval: NSTimeInterval, block: () -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timerInterval * Double(NSEC_PER_SEC))), queue, block)
    }
}
