//
//  ShowWordPointerStream.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/14/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RxCocoa
import RxSwift

protocol ShowWordPointerStream: class {
    var command: Observable<Void> { get }
}

protocol MutableShowWordPointerStream: ShowWordPointerStream {
    func showWordPointer()
}

class ShowWordPointerStreamImpl: MutableShowWordPointerStream {

    private let relay = PublishRelay<Void>()

    var command: Observable<Void> {
        return relay.asObservable()
    }

    func showWordPointer() {
        relay.accept(())
    }
}
