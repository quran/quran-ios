//
//  AyahTextStorageProtocol.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AyahTextStorageProtocol {
    func getAyahTextForNumber(number: AyahNumber) throws -> String
}

