//
//  PlayFromAyahStream.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RxCocoa
import RxSwift

protocol PlayFromAyahStream: class {
    var ayah: Observable<AyahNumber> { get }
}

protocol MutablePlayFromAyahStream: PlayFromAyahStream {
    func playFrom(ayah: AyahNumber)
}

class PlayFromAyahStreamImpl: MutablePlayFromAyahStream {

    private let relay = PublishRelay<AyahNumber>()

    var ayah: Observable<AyahNumber> {
        return relay.asObservable()
    }

    func playFrom(ayah: AyahNumber) {
        relay.accept(ayah)
    }
}
