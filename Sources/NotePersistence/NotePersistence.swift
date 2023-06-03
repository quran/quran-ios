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
    func notes() -> AnyPublisher<[NotePersistenceModel], Never>
    func setNote(_ note: String?, verses: [VersePersistenceModel], color: Int) -> Promise<NotePersistenceModel>
    func removeNotes(with verses: [VersePersistenceModel]) -> Promise<[NotePersistenceModel]>
}
