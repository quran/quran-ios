//
//  QueuingPlayer.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import QueuePlayer

protocol QueuingPlayer: AnyObject {
    var actions: QueuePlayerActions? { get set }

    func play(request: AudioRequest)
    func pause()
    func resume()
    func stop()
    func stepForward()
    func stepBackward()
}

extension QueuePlayer: QueuingPlayer {
}
