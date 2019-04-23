//
//  AyahWord.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/19/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

struct AyahWord {

    enum TextType: Int {
        case translation
        case transliteration
    }

    enum WordType: String {
        case word
        case end
        case pause
        case sajdah
        case rubHizb = "rub-el-hizb"
    }

    struct Position: Equatable {
        let ayah: AyahNumber
        let position: Int
        let frame: CGRect

        static func == (lhs: Position, rhs: Position) -> Bool {
            return lhs.ayah == rhs.ayah && lhs.position == rhs.position && lhs.frame == rhs.frame
        }
    }

    let position: Position
    let text: String?
    let textType: TextType
}
