//
//  LastPagesPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/5/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol LastPagesPersistence {
    func retrieveAll() -> [LastPage]
    func add(page: Int) -> LastPage
    func update(page: LastPage, toPage: Int) -> LastPage
}
