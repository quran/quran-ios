//
//  RunloopLock.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/27/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Darwin
import Foundation

enum BlockingError: Error {
    case timeout
}

private typealias AtomicInt = Int32
private let AtomicIncrement = OSAtomicIncrement32Barrier
private let AtomicDecrement = OSAtomicDecrement32Barrier

private let runLoopMode: CFRunLoopMode = CFRunLoopMode.defaultMode
private let runLoopModeRaw = runLoopMode.rawValue

final class RunLoopLock {
    let _currentRunLoop: CFRunLoop

    private var _calledRun: AtomicInt = 0
    private var _calledStop: AtomicInt = 0
    private var _timeout: TimeInterval?

    init(timeout: TimeInterval?) {
        _timeout = timeout
        _currentRunLoop = CFRunLoopGetCurrent()
    }

    func dispatch(_ action: @escaping () -> ()) {
        CFRunLoopPerformBlock(_currentRunLoop, runLoopModeRaw, action)
        CFRunLoopWakeUp(_currentRunLoop)
    }

    func stop() {
        if AtomicIncrement(&_calledStop) != 1 {
            return
        }
        CFRunLoopPerformBlock(_currentRunLoop, runLoopModeRaw) {
            CFRunLoopStop(self._currentRunLoop)
        }
        CFRunLoopWakeUp(_currentRunLoop)
    }

    func run() throws {
        if AtomicIncrement(&_calledRun) != 1 {
            fatalError("Run can be only called once")
        }
        if let timeout = _timeout {
            switch CFRunLoopRunInMode(runLoopMode, timeout, false) {
            case .finished:
                return
            case .handledSource:
                return
            case .stopped:
                return
            case .timedOut:
                throw BlockingError.timeout
            }
        }
        else {
            CFRunLoopRun()
        }
    }
}
