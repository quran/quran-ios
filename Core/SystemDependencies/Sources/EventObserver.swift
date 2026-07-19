//
//  EventObserver.swift
//
//
//  Created by Mohamed Afifi on 2023-11-05.
//

public protocol EventObserver {
    func notify() async
    func waitForNextEvent() async
}

extension EventObserver {
    public func callAsFunction() async {
        await notify()
    }
}
