//
//  AyahInfoStorage.swift
//  Quran
//
//  Created by Ahmed El-Helw on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AyahInfoStorage {
    func getAyahInfoForPage(_ page: Int) throws -> [AyahNumber : [AyahInfo]]
    func getAyahInfoForSuraAyah(_ sura: Int, ayah: Int) throws -> [AyahInfo]
}
