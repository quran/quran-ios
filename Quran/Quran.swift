//
//  Quran.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//
import Foundation

struct Quran {

    static let arabicBasmAllah = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"

    static let QuranPagesRange: CountableClosedRange<Int> = 1...PageSuraStart.count
    static let QuranSurasRange: CountableClosedRange<Int> = 1...SuraPageStart.count
    static let QuranJuzsRange: CountableClosedRange<Int>  = 1...JuzPageStart.count

    static let NumberOfQuartersPerJuz = Quarters.count / JuzPageStart.count

    static let SuraPageStart: [Int] = [
        1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 262,
        267, 282, 293, 305, 312, 322, 332, 342, 350, 359, 367, 377, 385, 396,
        404, 411, 415, 418, 428, 434, 440, 446, 453, 458, 467, 477, 483, 489,
        496, 499, 502, 507, 511, 515, 518, 520, 523, 526, 528, 531, 534, 537,
        542, 545, 549, 551, 553, 554, 556, 558, 560, 562, 564, 566, 568, 570,
        572, 574, 575, 577, 578, 580, 582, 583, 585, 586, 587, 587, 589, 590,
        591, 591, 592, 593, 594, 595, 595, 596, 596, 597, 597, 598, 598, 599,
        599, 600, 600, 601, 601, 601, 602, 602, 602, 603, 603, 603, 604, 604,
        604
    ]

    static let PageSuraStart: [Int] = [
        1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
        6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9,
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10,
        10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
        11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 13, 13,
        13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 16,
        16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17,
        17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
        19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21,
        21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22,
        22, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24,
        24, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
        27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28,
        28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 30, 30, 30, 30, 30, 30, 31, 31,
        31, 31, 32, 32, 32, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 34, 34, 34,
        34, 34, 34, 34, 35, 35, 35, 35, 35, 35, 36, 36, 36, 36, 36, 37, 37, 37,
        37, 37, 37, 37, 38, 38, 38, 38, 38, 38, 39, 39, 39, 39, 39, 39, 39, 39,
        39, 40, 40, 40, 40, 40, 40, 40, 40, 40, 41, 41, 41, 41, 41, 41, 42, 42,
        42, 42, 42, 42, 42, 43, 43, 43, 43, 43, 43, 44, 44, 44, 45, 45, 45, 45,
        46, 46, 46, 46, 47, 47, 47, 47, 48, 48, 48, 48, 48, 49, 49, 50, 50, 50,
        51, 51, 51, 52, 52, 53, 53, 53, 54, 54, 54, 55, 55, 55, 56, 56, 56, 57,
        57, 57, 57, 58, 58, 58, 58, 59, 59, 59, 60, 60, 60, 61, 62, 62, 63, 64,
        64, 65, 65, 66, 66, 67, 67, 67, 68, 68, 69, 69, 70, 70, 71, 72, 72, 73,
        73, 74, 74, 75, 76, 76, 77, 78, 78, 79, 80, 81, 82, 83, 83, 85, 86, 87,
        89, 89, 91, 92, 95, 97, 98, 100, 103, 106, 109, 112
    ]

    static let PageAyahStart: [Int] = [
        1, 1, 6, 17, 25, 30, 38, 49, 58, 62, 70, 77, 84, 89, 94, 102, 106, 113,
        120, 127, 135, 142, 146, 154, 164, 170, 177, 182, 187, 191, 197, 203,
        211, 216, 220, 225, 231, 234, 238, 246, 249, 253, 257, 260, 265, 270,
        275, 282, 283, 1, 10, 16, 23, 30, 38, 46, 53, 62, 71, 78, 84, 92, 101,
        109, 116, 122, 133, 141, 149, 154, 158, 166, 174, 181, 187, 195, 1, 7,
        12, 15, 20, 24, 27, 34, 38, 45, 52, 60, 66, 75, 80, 87, 92, 95, 102,
        106, 114, 122, 128, 135, 141, 148, 155, 163, 171, 176, 3, 6, 10, 14,
        18, 24, 32, 37, 42, 46, 51, 58, 65, 71, 77, 83, 90, 96, 104, 109, 114,
        1, 9, 19, 28, 36, 45, 53, 60, 69, 74, 82, 91, 95, 102, 111, 119, 125,
        132, 138, 143, 147, 152, 158, 1, 12, 23, 31, 38, 44, 52, 58, 68, 74,
        82, 88, 96, 105, 121, 131, 138, 144, 150, 156, 160, 164, 171, 179, 188,
        196, 1, 9, 17, 26, 34, 41, 46, 53, 62, 70, 1, 7, 14, 21, 27, 32, 37,
        41, 48, 55, 62, 69, 73, 80, 87, 94, 100, 107, 112, 118, 123, 1, 7, 15,
        21, 26, 34, 43, 54, 62, 71, 79, 89, 98, 107, 6, 13, 20, 29, 38, 46, 54,
        63, 72, 82, 89, 98, 109, 118, 5, 15, 23, 31, 38, 44, 53, 64, 70, 79,
        87, 96, 104, 1, 6, 14, 19, 29, 35, 43, 6, 11, 19, 25, 34, 43, 1, 16,
        32, 52, 71, 91, 7, 15, 27, 35, 43, 55, 65, 73, 80, 88, 94, 103, 111,
        119, 1, 8, 18, 28, 39, 50, 59, 67, 76, 87, 97, 105, 5, 16, 21, 28, 35,
        46, 54, 62, 75, 84, 98, 1, 12, 26, 39, 52, 65, 77, 96, 13, 38, 52, 65,
        77, 88, 99, 114, 126, 1, 11, 25, 36, 45, 58, 73, 82, 91, 102, 1, 6,
        16, 24, 31, 39, 47, 56, 65, 73, 1, 18, 28, 43, 60, 75, 90, 105, 1,
        11, 21, 28, 32, 37, 44, 54, 59, 62, 3, 12, 21, 33, 44, 56, 68, 1, 20,
        40, 61, 84, 112, 137, 160, 184, 207, 1, 14, 23, 36, 45, 56, 64, 77,
        89, 6, 14, 22, 29, 36, 44, 51, 60, 71, 78, 85, 7, 15, 24, 31, 39, 46,
        53, 64, 6, 16, 25, 33, 42, 51, 1, 12, 20, 29, 1, 12, 21, 1, 7, 16, 23,
        31, 36, 44, 51, 55, 63, 1, 8, 15, 23, 32, 40, 49, 4, 12, 19, 31, 39,
        45, 13, 28, 41, 55, 71, 1, 25, 52, 77, 103, 127, 154, 1, 17, 27, 43,
        62, 84, 6, 11, 22, 32, 41, 48, 57, 68, 75, 8, 17, 26, 34, 41, 50, 59,
        67, 78, 1, 12, 21, 30, 39, 47, 1, 11, 16, 23, 32, 45, 52, 11, 23, 34,
        48, 61, 74, 1, 19, 40, 1, 14, 23, 33, 6, 15, 21, 29, 1, 12, 20, 30, 1,
        10, 16, 24, 29, 5, 12, 1, 16, 36, 7, 31, 52, 15, 32, 1, 27, 45, 7, 28,
        50, 17, 41, 68, 17, 51, 77, 4, 12, 19, 25, 1, 7, 12, 22, 4, 10, 17, 1,
        6, 12, 6, 1, 9, 5, 1, 10, 1, 6, 1, 8, 1, 13, 27, 16, 43, 9, 35, 11, 40,
        11, 1, 14, 1, 20, 18, 48, 20, 6, 26, 20, 1, 31, 16, 1, 1, 1, 7, 35, 1,
        1, 16, 1, 24, 1, 15, 1, 1, 8, 10, 1, 1, 1, 1
    ]

    static let JuzPageStart: [Int] = [
        1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
        201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
        402, 422, 442, 462, 482, 502, 522, 542, 562, 582
    ]

    static let PageRubStart: [Int] = [
        -1, -1, -1, -1, 1, -1, 2, -1, 3, -1, 4, -1, -1, 5, -1, -1, 6, -1, 7,
        -1, -1, 8, -1, 9, -1, -1, 10, -1, 11, -1, -1, 12, -1, 13, -1, -1, 14,
        -1, 15, -1, -1, 16, -1, 17, -1, 18, -1, -1, 19, -1, 20, -1, -1, 21, -1,
        22, -1, -1, 23, -1, -1, 24, -1, 25, -1, -1, 26, -1, 27, -1, -1, 28, -1,
        29, -1, -1, 30, -1, 31, -1, -1, 32, -1, 33, -1, -1, 34, -1, 35, -1, -1,
        36, -1, 37, -1, -1, 38, -1, -1, 39, -1, 40, -1, 41, -1, 42, -1, -1, 43,
        -1, -1, 44, -1, 45, -1, -1, 46, -1, 47, -1, 48, -1, -1, 49, -1, 50, -1,
        -1, 51, -1, -1, 52, -1, 53, -1, -1, 54, -1, -1, 55, -1, 56, -1, 57, -1,
        58, -1, 59, -1, -1, 60, -1, -1, 61, -1, 62, -1, 63, -1, -1, -1, 64, -1,
        65, -1, -1, 66, -1, -1, 67, -1, -1, 68, -1, 69, -1, 70, -1, 71, -1, -1,
        72, -1, 73, -1, -1, 74, -1, 75, -1, -1, 76, -1, 77, -1, 78, -1, -1, 79,
        -1, 80, -1, -1, 81, -1, 82, -1, -1, 83, -1, -1, 84, -1, 85, -1, -1, 86,
        -1, 87, -1, -1, 88, -1, 89, -1, 90, -1, 91, -1, -1, 92, -1, 93, -1, -1,
        94, -1, 95, -1, -1, -1, 96, -1, 97, -1, -1, 98, -1, 99, -1, -1, 100, -1,
        101, -1, 102, -1, -1, 103, -1, -1, 104, -1, 105, -1, -1, 106, -1, -1,
        107, -1, 108, -1, -1, 109, -1, 110, -1, -1, 111, -1, 112, -1, 113, -1,
        -1, 114, -1, 115, -1, -1, 116, -1, -1, 117, -1, 118, -1, 119, -1, -1,
        120, -1, 121, -1, 122, -1, -1, 123, -1, -1, 124, -1, -1, 125, -1, 126,
        -1, 127, -1, -1, 128, -1, 129, -1, 130, -1, -1, 131, -1, -1, 132, -1,
        133, -1, 134, -1, -1, 135, -1, -1, 136, -1, 137, -1, -1, 138, -1, -1,
        139, -1, 140, -1, 141, -1, 142, -1, -1, 143, -1, -1, 144, -1, 145, -1,
        -1, 146, -1, 147, -1, 148, -1, -1, 149, -1, -1, 150, -1, 151, -1, -1,
        152, -1, 153, -1, 154, -1, -1, 155, -1, -1, 156, -1, 157, -1, 158, -1,
        -1, 159, -1, -1, 160, -1, 161, -1, -1, 162, -1, -1, 163, -1, -1, 164,
        -1, 165, -1, -1, 166, -1, 167, -1, 168, -1, -1, 169, 170, -1, -1, 171,
        -1, 172, -1, 173, -1, -1, 174, -1, -1, 175, -1, -1, 176, -1, 177, -1,
        178, -1, -1, 179, -1, 180, -1, -1, 181, -1, 182, -1, -1, 183, -1, -1,
        184, -1, 185, -1, -1, 186, -1, 187, -1, -1, 188, -1, 189, -1, -1, 190,
        -1, 191, -1, -1, 192, -1, 193, -1, 194, -1, 195, -1, -1, 196, -1, 197,
        -1, -1, 198, -1, -1, 199, -1, -1, 200, -1, -1, 201, -1, 202, -1, -1,
        203, -1, -1, 204, -1, 205, -1, 206, -1, 207, -1, -1, 208, -1, 209, -1,
        210, -1, -1, 211, -1, 212, -1, -1, 213, -1, 214, -1, -1, 215, -1, -1,
        216, -1, 217, -1, -1, 218, -1, -1, 219, -1, -1, 220, 221, -1, -1, -1,
        222, -1, 223, -1, 224, -1, 225, -1, 226, -1, -1, 227, -1, -1, 228, -1,
        -1, 229, -1, 230, -1, 231, -1, -1, 232, -1, -1, 233, -1, 234, -1, 235,
        -1, 236, -1, -1, 237, -1, 238, -1, -1, 239, -1, -1, -1, -1, -1
    ]

    static let SuraNumberOfAyahs: [Int] = [
        7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111,
        43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77,
        227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75,
        85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55,
        78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
        44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25,
        22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
        11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ]

    static let SuraIsMakki: [Bool] = [
        // 1 - 10
        true, false, false, false, false, true, true, false, false, true,
        // 11 - 20
        true, true, false, true, true, true, true, true, true, true,
        // 21 - 30
        true, false, true, false, true, true, true, true, true, true,
        // 31 - 40
        true, true, false, true, true, true, true, true, true, true,
        // 41 - 50
        true, true, true, true, true, true, false, false, false, true,
        // 51 - 60
        true, true, true, true, false, true, false, false, false, false,
        // 61 - 70
        false, false, false, false, false, false, true, true, true, true,
        // 71 - 80
        true, true, true, true, true, false, true, true, true, true,
        // 81 - 90
        true, true, true, true, true, true, true, true, true, true,
        // 91 - 100
        true, true, true, true, true, true, true, false, false, true,
        // 101 - 110
        true, true, true, true, true, true, true, true, true, false,
        // 111 - 114
        true, true, true, true
    ]

    static let Quarters: [AyahNumber] = [
        // hizb 1
        AyahNumber(sura:1, ayah:1), AyahNumber(sura:2, ayah:26), AyahNumber(sura:2, ayah:44), AyahNumber(sura:2, ayah:60),

        // hizb 2
        AyahNumber(sura:2, ayah:75), AyahNumber(sura:2, ayah:92), AyahNumber(sura:2, ayah:106), AyahNumber(sura:2, ayah:124),

        // hizb 3
        AyahNumber(sura:2, ayah:142), AyahNumber(sura:2, ayah:158), AyahNumber(sura:2, ayah:177), AyahNumber(sura:2, ayah:189),

        // hizb 4
        AyahNumber(sura:2, ayah:203), AyahNumber(sura:2, ayah:219), AyahNumber(sura:2, ayah:233), AyahNumber(sura:2, ayah:243),

        // hizb 5
        AyahNumber(sura:2, ayah:253), AyahNumber(sura:2, ayah:263), AyahNumber(sura:2, ayah:272), AyahNumber(sura:2, ayah:283),

        // hizb 6
        AyahNumber(sura:3, ayah:15), AyahNumber(sura:3, ayah:33), AyahNumber(sura:3, ayah:52), AyahNumber(sura:3, ayah:75),

        // hizb 7
        AyahNumber(sura:3, ayah:93), AyahNumber(sura:3, ayah:113), AyahNumber(sura:3, ayah:133), AyahNumber(sura:3, ayah:153),

        // hizb 8
        AyahNumber(sura:3, ayah:171), AyahNumber(sura:3, ayah:186), AyahNumber(sura:4, ayah:1), AyahNumber(sura:4, ayah:12),

        // hizb 9
        AyahNumber(sura:4, ayah:24), AyahNumber(sura:4, ayah:36), AyahNumber(sura:4, ayah:58), AyahNumber(sura:4, ayah:74),

        // hizb 10
        AyahNumber(sura:4, ayah:88), AyahNumber(sura:4, ayah:100), AyahNumber(sura:4, ayah:114), AyahNumber(sura:4, ayah:135),

        // hizb 11
        AyahNumber(sura:4, ayah:148), AyahNumber(sura:4, ayah:163), AyahNumber(sura:5, ayah:1), AyahNumber(sura:5, ayah:12),

        // hizb 12
        AyahNumber(sura:5, ayah:27), AyahNumber(sura:5, ayah:41), AyahNumber(sura:5, ayah:51), AyahNumber(sura:5, ayah:67),

        // hizb 13
        AyahNumber(sura:5, ayah:82), AyahNumber(sura:5, ayah:97), AyahNumber(sura:5, ayah:109), AyahNumber(sura:6, ayah:13),

        // hizb 14
        AyahNumber(sura:6, ayah:36), AyahNumber(sura:6, ayah:59), AyahNumber(sura:6, ayah:74), AyahNumber(sura:6, ayah:95),

        // hizb 15
        AyahNumber(sura:6, ayah:111), AyahNumber(sura:6, ayah:127), AyahNumber(sura:6, ayah:141), AyahNumber(sura:6, ayah:151),

        // hizb 16
        AyahNumber(sura:7, ayah:1), AyahNumber(sura:7, ayah:31), AyahNumber(sura:7, ayah:47), AyahNumber(sura:7, ayah:65),

        // hizb 17
        AyahNumber(sura:7, ayah:88), AyahNumber(sura:7, ayah:117), AyahNumber(sura:7, ayah:142), AyahNumber(sura:7, ayah:156),

        // hizb 18
        AyahNumber(sura:7, ayah:171), AyahNumber(sura:7, ayah:189), AyahNumber(sura:8, ayah:1), AyahNumber(sura:8, ayah:22),

        // hizb 19
        AyahNumber(sura:8, ayah:41), AyahNumber(sura:8, ayah:61), AyahNumber(sura:9, ayah:1), AyahNumber(sura:9, ayah:19),

        // hizb 20
        AyahNumber(sura:9, ayah:34), AyahNumber(sura:9, ayah:46), AyahNumber(sura:9, ayah:60), AyahNumber(sura:9, ayah:75),

        // hizb 21
        AyahNumber(sura:9, ayah:93), AyahNumber(sura:9, ayah:111), AyahNumber(sura:9, ayah:122), AyahNumber(sura:10, ayah:11),

        // hizb 22
        AyahNumber(sura:10, ayah:26), AyahNumber(sura:10, ayah:53), AyahNumber(sura:10, ayah:71), AyahNumber(sura:10, ayah:90),

        // hizb 23
        AyahNumber(sura:11, ayah:6), AyahNumber(sura:11, ayah:24), AyahNumber(sura:11, ayah:41), AyahNumber(sura:11, ayah:61),

        // hizb 24
        AyahNumber(sura:11, ayah:84), AyahNumber(sura:11, ayah:108), AyahNumber(sura:12, ayah:7), AyahNumber(sura:12, ayah:30),

        // hizb 25
        AyahNumber(sura:12, ayah:53), AyahNumber(sura:12, ayah:77), AyahNumber(sura:12, ayah:101), AyahNumber(sura:13, ayah:5),

        // hizb 26
        AyahNumber(sura:13, ayah:19), AyahNumber(sura:13, ayah:35), AyahNumber(sura:14, ayah:10), AyahNumber(sura:14, ayah:28),

        // hizb 27
        AyahNumber(sura:15, ayah:1), AyahNumber(sura:15, ayah:49), AyahNumber(sura:16, ayah:1), AyahNumber(sura:16, ayah:30),

        // hizb 28
        AyahNumber(sura:16, ayah:51), AyahNumber(sura:16, ayah:75), AyahNumber(sura:16, ayah:90), AyahNumber(sura:16, ayah:111),

        // hizb 29
        AyahNumber(sura:17, ayah:1), AyahNumber(sura:17, ayah:23), AyahNumber(sura:17, ayah:50), AyahNumber(sura:17, ayah:70),

        // hizb 30
        AyahNumber(sura:17, ayah:99), AyahNumber(sura:18, ayah:17), AyahNumber(sura:18, ayah:32), AyahNumber(sura:18, ayah:51),

        // hizb 31
        AyahNumber(sura:18, ayah:75), AyahNumber(sura:18, ayah:99), AyahNumber(sura:19, ayah:22), AyahNumber(sura:19, ayah:59),

        // hizb 32
        AyahNumber(sura:20, ayah:1), AyahNumber(sura:20, ayah:55), AyahNumber(sura:20, ayah:83), AyahNumber(sura:20, ayah:111),

        // hizb 33
        AyahNumber(sura:21, ayah:1), AyahNumber(sura:21, ayah:29), AyahNumber(sura:21, ayah:51), AyahNumber(sura:21, ayah:83),

        // hizb 34
        AyahNumber(sura:22, ayah:1), AyahNumber(sura:22, ayah:19), AyahNumber(sura:22, ayah:38), AyahNumber(sura:22, ayah:60),

        // hizb 35
        AyahNumber(sura:23, ayah:1), AyahNumber(sura:23, ayah:36), AyahNumber(sura:23, ayah:75), AyahNumber(sura:24, ayah:1),

        // hizb 36
        AyahNumber(sura:24, ayah:21), AyahNumber(sura:24, ayah:35), AyahNumber(sura:24, ayah:53), AyahNumber(sura:25, ayah:1),

        // hizb 37
        AyahNumber(sura:25, ayah:21), AyahNumber(sura:25, ayah:53), AyahNumber(sura:26, ayah:1), AyahNumber(sura:26, ayah:52),

        // hizb 38
        AyahNumber(sura:26, ayah:111), AyahNumber(sura:26, ayah:181), AyahNumber(sura:27, ayah:1), AyahNumber(sura:27, ayah:27),

        // hizb 39
        AyahNumber(sura:27, ayah:56), AyahNumber(sura:27, ayah:82), AyahNumber(sura:28, ayah:12), AyahNumber(sura:28, ayah:29),

        // hizb 40
        AyahNumber(sura:28, ayah:51), AyahNumber(sura:28, ayah:76), AyahNumber(sura:29, ayah:1), AyahNumber(sura:29, ayah:26),

        // hizb 41
        AyahNumber(sura:29, ayah:46), AyahNumber(sura:30, ayah:1), AyahNumber(sura:30, ayah:31), AyahNumber(sura:30, ayah:54),

        // hizb 42
        AyahNumber(sura:31, ayah:22), AyahNumber(sura:32, ayah:11), AyahNumber(sura:33, ayah:1), AyahNumber(sura:33, ayah:18),

        // hizb 43
        AyahNumber(sura:33, ayah:31), AyahNumber(sura:33, ayah:51), AyahNumber(sura:33, ayah:60), AyahNumber(sura:34, ayah:10),

        // hizb 44
        AyahNumber(sura:34, ayah:24), AyahNumber(sura:34, ayah:46), AyahNumber(sura:35, ayah:15), AyahNumber(sura:35, ayah:41),

        // hizb 45
        AyahNumber(sura:36, ayah:28), AyahNumber(sura:36, ayah:60), AyahNumber(sura:37, ayah:22), AyahNumber(sura:37, ayah:83),

        // hizb 46
        AyahNumber(sura:37, ayah:145), AyahNumber(sura:38, ayah:21), AyahNumber(sura:38, ayah:52), AyahNumber(sura:39, ayah:8),

        // hizb 47
        AyahNumber(sura:39, ayah:32), AyahNumber(sura:39, ayah:53), AyahNumber(sura:40, ayah:1), AyahNumber(sura:40, ayah:21),

        // hizb 48
        AyahNumber(sura:40, ayah:41), AyahNumber(sura:40, ayah:66), AyahNumber(sura:41, ayah:9), AyahNumber(sura:41, ayah:25),

        // hizb 49
        AyahNumber(sura:41, ayah:47), AyahNumber(sura:42, ayah:13), AyahNumber(sura:42, ayah:27), AyahNumber(sura:42, ayah:51),

        // hizb 50
        AyahNumber(sura:43, ayah:24), AyahNumber(sura:43, ayah:57), AyahNumber(sura:44, ayah:17), AyahNumber(sura:45, ayah:12),

        // hizb 51
        AyahNumber(sura:46, ayah:1), AyahNumber(sura:46, ayah:21), AyahNumber(sura:47, ayah:10), AyahNumber(sura:47, ayah:33),

        // hizb 52
        AyahNumber(sura:48, ayah:18), AyahNumber(sura:49, ayah:1), AyahNumber(sura:49, ayah:14), AyahNumber(sura:50, ayah:27),

        // hizb 53
        AyahNumber(sura:51, ayah:31), AyahNumber(sura:52, ayah:24), AyahNumber(sura:53, ayah:26), AyahNumber(sura:54, ayah:9),

        // hizb 54
        AyahNumber(sura:55, ayah:1), AyahNumber(sura:56, ayah:1), AyahNumber(sura:56, ayah:75), AyahNumber(sura:57, ayah:16),

        // hizb 55
        AyahNumber(sura:58, ayah:1), AyahNumber(sura:58, ayah:14), AyahNumber(sura:59, ayah:11), AyahNumber(sura:60, ayah:7),

        // hizb 56
        AyahNumber(sura:62, ayah:1), AyahNumber(sura:63, ayah:4), AyahNumber(sura:65, ayah:1), AyahNumber(sura:66, ayah:1),

        // hizb 57
        AyahNumber(sura:67, ayah:1), AyahNumber(sura:68, ayah:1), AyahNumber(sura:69, ayah:1), AyahNumber(sura:70, ayah:19),

        // hizb 58
        AyahNumber(sura:72, ayah:1), AyahNumber(sura:73, ayah:20), AyahNumber(sura:75, ayah:1), AyahNumber(sura:76, ayah:19),

        // hizb 59
        AyahNumber(sura:78, ayah:1), AyahNumber(sura:80, ayah:1), AyahNumber(sura:82, ayah:1), AyahNumber(sura:84, ayah:1),

        // hizb 60
        AyahNumber(sura:87, ayah:1), AyahNumber(sura:90, ayah:1), AyahNumber(sura:94, ayah:1), AyahNumber(sura:100, ayah:9)
        ]
}

extension Quran {
    static func startAyahForPage(_ page: Int) -> AyahNumber {
        return AyahNumber(sura: PageSuraStart[page - 1], ayah: PageAyahStart[page - 1])
    }

    static func numberOfAyahsForSura(_ sura: Int) -> Int {
        return SuraNumberOfAyahs[sura - 1]
    }

    static func firstPage() -> QuranPage {
        return quranPageForPageNumber(1)
    }

    static func quranPageForPageNumber(_ page: Int) -> QuranPage {
        return QuranPage(pageNumber: page, startAyah: startAyahForPage(page), juzNumber: Juz.juzFromPage(page).juzNumber)
    }
}

extension Quran {
    static func nameForSura(_ sura: Int, withPrefix: Bool = false) -> String {
        let suraName = NSLocalizedString("sura_names[\(sura - 1)]", tableName: "Suras", comment: "")
        if !withPrefix {
            return suraName
        }
        let suraFormat = NSLocalizedString("quran_sura_title", tableName: "Android", comment: "")
        return String(format: suraFormat, suraName)
    }
}

extension AyahNumber {

    var localizedName: String {
        let ayahNumberString = String.localizedStringWithFormat(NSLocalizedString("quran_ayah", tableName: "Android", comment: ""), ayah)
        let suraName = Quran.nameForSura(sura)
        return "\(suraName), \(ayahNumberString)"
    }
}

extension Quran {

    static func range(forPage page: Int) -> VerseRange {
        let lowerBound = startAyahForPage(page)
        let finder = PageBasedLastAyahFinder()
        let upperBound = finder.findLastAyah(startAyah: lowerBound, page: page)
        return VerseRange(lowerBound: lowerBound, upperBound: upperBound)
    }
}
