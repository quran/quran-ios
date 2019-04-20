//
//  HideWordPointerStream.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/14/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RxCocoa
import RxSwift

protocol HideWordPointerStream: class {
    var command: Observable<Void> { get }
}

protocol MutableHideWordPointerStream: HideWordPointerStream {
    func hideWordPointer()
}

class HideWordPointerStreamImpl: MutableHideWordPointerStream {

    private let relay = PublishRelay<Void>()

    var command: Observable<Void> {
        return relay.asObservable()
    }

    func hideWordPointer() {
        relay.accept(())
    }
}
