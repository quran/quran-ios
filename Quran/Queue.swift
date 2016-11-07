//
//  Queue.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Queue {

    let queue: DispatchQueue

    static let main = Queue(queue: DispatchQueue.main)
    static let background = Queue(queue: DispatchQueue.global())

    func async(_ block: @escaping () -> Void) {
        queue.async(execute: block)
    }

    func after(_ timerInterval: TimeInterval, block: @escaping () -> Void) {
        queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(timerInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: block)
    }

    func async<T>(_ background: @escaping () -> T, onMain: @escaping (T) -> Void) {
        async {
            let result = background()
            Queue.main.async {
                onMain(result)
            }
        }
    }

    func tryAsync<T>(_ background: @escaping () throws -> T, onMain: @escaping (Result<T>) -> Void) {
        async {
            do {
                let result = try background()
                Queue.main.async {
                    onMain(.success(result))
                }
            } catch {
                Queue.main.async {
                    onMain(.failure(error))
                }
            }

        }
    }

    func asyncSuccess<T>(_ background: @escaping () throws -> T, onMain: @escaping (T) -> Void) {
        tryAsync(background) { result in
            switch result {
            case .success(let value): onMain(value)
            case .failure: break
            }
        }
    }
}
