//
//  NotePersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import Foundation
import PromiseKit
import QuranKit

public protocol NotePersistence {
    func notes() -> AnyPublisher<[NoteDTO], Never>
    func setNote(_ note: String?, verses: [VerseDTO], color: Int) -> Promise<NoteDTO>
    func removeNotes(with verses: [VerseDTO]) -> Promise<[NoteDTO]>
}
