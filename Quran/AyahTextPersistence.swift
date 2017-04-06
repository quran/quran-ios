//
//  AyahTextPersistence.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AyahTextPersistence {
    func getAyahTextForNumber(_ number: AyahNumber) throws -> String
    func getOptionalAyahText(forNumber: AyahNumber) throws -> String?
}
